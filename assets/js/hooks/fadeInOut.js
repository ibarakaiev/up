export const FadeInOut = {
  mounted() {
    this.el.style.transition = "opacity 0.5s";
    this.el.style.opacity = 0;

    setTimeout(() => {
      this.el.style.opacity = 1;
    }, 1);
  },
  destroyed() {
    this.el.style.transition = "opacity 0.5s";
    this.el.style.opacity = 0;
  },
};
