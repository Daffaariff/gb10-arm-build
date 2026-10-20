// lkpub: publish already-encoded H.264 + Opus from stdin into a LiveKit room, no re-encoding.
//
// stdin: repeated [type byte 'V'|'M'|'L'|'A'][uint32 big-endian length][payload]
//   V/M/L = one H.264 access unit (Annex-B) of the high/medium/low layer, 1/FPS seconds
//   A = one Opus packet, 20 ms
// env: LK_URL, LK_TOKEN, LK_WIDTH, LK_HEIGHT, LK_FPS (default 25), LK_LAYERS (simulcast, e.g. 3840x2160,1920x1080,960x540)
package main

import (
	"bufio"
	"encoding/binary"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/livekit/protocol/livekit"
	lksdk "github.com/livekit/server-sdk-go/v2"
	"github.com/pion/webrtc/v4"
	"github.com/pion/webrtc/v4/pkg/media"
)

func envInt(k string, def int) int {
	if v, err := strconv.Atoi(os.Getenv(k)); err == nil {
		return v
	}
	return def
}

// readMsg returns the next framed message from r.
func readMsg(r io.Reader) (byte, []byte, error) {
	var hdr [5]byte
	if _, err := io.ReadFull(r, hdr[:]); err != nil {
		return 0, nil, err
	}
	n := binary.BigEndian.Uint32(hdr[1:])
	buf := make([]byte, n)
	if _, err := io.ReadFull(r, buf); err != nil {
		return 0, nil, err
	}
	return hdr[0], buf, nil
}

func main() {
	if len(os.Args) > 1 && os.Args[1] == "selfcheck" {
		selfcheck()
		return
	}
	url, token := os.Getenv("LK_URL"), os.Getenv("LK_TOKEN")
	if url == "" || token == "" {
		log.Fatal("LK_URL and LK_TOKEN are required")
	}
	fps := envInt("LK_FPS", 25)
	frame := time.Second / time.Duration(fps)

	room, err := lksdk.ConnectToRoomWithToken(url, token, &lksdk.RoomCallback{}, lksdk.WithAutoSubscribe(false))
	if err != nil {
		log.Fatalf("connect: %v", err)
	}
	defer room.Disconnect()

	// NOTE: NVENC gives High profile; 640034 = High level 5.2 covers 4K at 25-30 fps
	h264 := webrtc.RTPCodecCapability{
		MimeType: webrtc.MimeTypeH264, ClockRate: 90000,
		SDPFmtpLine: "level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640034",
	}
	pubOpts := &lksdk.TrackPublicationOptions{
		Name: "avatar", Source: livekit.TrackSource_CAMERA,
		VideoWidth: envInt("LK_WIDTH", 0), VideoHeight: envInt("LK_HEIGHT", 0),
	}
	// NOTE: LK_LAYERS="3840x2160,1920x1080,960x540" -> simulcast (msg V/M/L = high/medium/low); else one track (V)
	layers := parseLayers(os.Getenv("LK_LAYERS"))
	videos := map[byte]*lksdk.LocalTrack{}
	if len(layers) > 1 {
		var tracks []*lksdk.LocalTrack
		for i, l := range layers {
			t, err := lksdk.NewLocalSampleTrack(h264, lksdk.WithSimulcast("avatar", &livekit.VideoLayer{
				Quality: l.quality, Width: l.w, Height: l.h}))
			if err != nil {
				log.Fatalf("video layer %d: %v", i, err)
			}
			videos[l.kind] = t
			tracks = append(tracks, t)
		}
		if _, err = room.LocalParticipant.PublishSimulcastTrack(tracks, pubOpts); err != nil {
			log.Fatalf("publish simulcast: %v", err)
		}
	} else {
		video, err := lksdk.NewLocalSampleTrack(h264)
		if err != nil {
			log.Fatalf("video track: %v", err)
		}
		if _, err = room.LocalParticipant.PublishTrack(video, pubOpts); err != nil {
			log.Fatalf("publish video: %v", err)
		}
		videos['V'] = video
	}
	audio, err := lksdk.NewLocalSampleTrack(webrtc.RTPCodecCapability{MimeType: webrtc.MimeTypeOpus, ClockRate: 48000, Channels: 2})
	if err != nil {
		log.Fatalf("audio track: %v", err)
	}
	if _, err = room.LocalParticipant.PublishTrack(audio, &lksdk.TrackPublicationOptions{
		Name: "voice", Source: livekit.TrackSource_MICROPHONE,
	}); err != nil {
		log.Fatalf("publish audio: %v", err)
	}
	fmt.Fprintf(os.Stderr, "[lkpub] publishing to %s (%dx%d @ %d fps, %d video layer(s))\n", url, envInt("LK_WIDTH", 0), envInt("LK_HEIGHT", 0), fps, len(videos))

	r := bufio.NewReaderSize(os.Stdin, 4<<20)
	for {
		t, payload, err := readMsg(r)
		if err != nil {
			if err != io.EOF {
				log.Printf("read: %v", err)
			}
			return
		}
		switch t {
		case 'V', 'M', 'L':
			if v := videos[t]; v != nil {
				err = v.WriteSample(media.Sample{Data: payload, Duration: frame}, nil)
			}
		case 'A':
			err = audio.WriteSample(media.Sample{Data: payload, Duration: 20 * time.Millisecond}, nil)
		}
		if err != nil {
			log.Printf("write %c: %v", t, err)
		}
	}
}

type layer struct {
	kind    byte
	w, h    uint32
	quality livekit.VideoQuality
}

// parseLayers: "WxH,WxH,..." highest first -> V/M/L layers with HIGH/MEDIUM/LOW quality.
func parseLayers(s string) []layer {
	kinds := []byte{'V', 'M', 'L'}
	q := []livekit.VideoQuality{livekit.VideoQuality_HIGH, livekit.VideoQuality_MEDIUM, livekit.VideoQuality_LOW}
	var out []layer
	for i, part := range strings.Split(s, ",") {
		var w, h uint32
		if i >= len(kinds) {
			break
		}
		if n, _ := fmt.Sscanf(strings.TrimSpace(part), "%dx%d", &w, &h); n == 2 {
			out = append(out, layer{kinds[i], w, h, q[i]})
		}
	}
	return out
}

func selfcheck() {
	if l := parseLayers("3840x2160, 1920x1080,960x540"); len(l) != 3 || l[1].kind != 'M' || l[2].w != 960 || l[0].quality != livekit.VideoQuality_HIGH {
		log.Fatalf("parseLayers: %+v", l)
	}
	if len(parseLayers("")) != 0 {
		log.Fatal("parseLayers empty")
	}
	pr, pw := io.Pipe()
	go func() {
		w := bufio.NewWriter(pw)
		for _, m := range []struct {
			t byte
			p string
		}{{'V', "abc"}, {'A', "de"}} {
			var hdr [5]byte
			hdr[0] = m.t
			binary.BigEndian.PutUint32(hdr[1:], uint32(len(m.p)))
			w.Write(hdr[:])
			w.WriteString(m.p)
		}
		w.Flush()
		pw.Close()
	}()
	t1, p1, _ := readMsg(pr)
	t2, p2, _ := readMsg(pr)
	_, _, end := readMsg(pr)
	if t1 != 'V' || string(p1) != "abc" || t2 != 'A' || string(p2) != "de" || end != io.EOF {
		log.Fatalf("selfcheck failed: %c %q %c %q %v", t1, p1, t2, p2, end)
	}
	fmt.Println("lkpub ok")
}
