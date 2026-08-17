import { useEffect } from 'react';
import Lenis from '@studio-freight/lenis';

export default function SmoothScroll() {
  useEffect(() => {
    // Initialize Lenis with a custom, constant smooth scroll speed
    const lenis = new Lenis({
      duration: 1.8, // Slower, highly controlled speed so users can't surpass it wildly
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)), // Buttery smooth easing curve
      direction: 'vertical', // vertical scrolling
      gestureDirection: 'vertical', // vertical scrolling
      smooth: true,
      mouseMultiplier: 1, // Controls how much the mouse wheel moves it
      smoothTouch: false,
      touchMultiplier: 2,
      infinite: false,
    });

    function raf(time: number) {
      lenis.raf(time);
      requestAnimationFrame(raf);
    }

    requestAnimationFrame(raf);

    return () => {
      lenis.destroy();
    };
  }, []);

  return null;
}
