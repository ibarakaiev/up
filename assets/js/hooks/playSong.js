export const PlaySong = {
  mounted() {
    let audio = new Audio("/audio/song.m4a");

    audio.play().catch((error) => {
      console.error("Audio playback failed:", error);
    });
  },
};
