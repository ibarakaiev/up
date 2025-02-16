export const LoadingEllipsis = {
  mounted() {
    let count = 0;
    const states = [".", "..", "..."];
    const originalText = this.el.textContent;
    const el = this.el;

    this.interval = setInterval(() => {
      el.textContent = originalText + states[count % states.length];
      count++;
    }, 333);
  },

  destroyed() {
    clearInterval(this.interval);
  },
};
