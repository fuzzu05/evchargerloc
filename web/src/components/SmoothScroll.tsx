import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import Lenis from '@studio-freight/lenis';

export default function SmoothScroll() {
  const location = useLocation();

  useEffect(() => {
    // Only apply smooth scrolling on the Landing Page
    if (location.pathname !== '/') return;

    const lenis = new Lenis({
      duration: 1.8, // Slower, highly controlled speed so users can't surpass it wildly
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)), // Buttery smooth easing curve
    });

    let frameId: number;
    function raf(time: number) {
      lenis.raf(time);
      frameId = requestAnimationFrame(raf);
    }

    frameId = requestAnimationFrame(raf);

    return () => {
      cancelAnimationFrame(frameId);
      lenis.destroy();
    };
  }, [location.pathname]);

  return null;
}
