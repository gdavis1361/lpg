import React, { useEffect, useRef, useState } from "react";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";

type WowRetroGridBackgroundProps = {
  className?: string;
  color?: string;
  lineColor?: string;
  dotColor?: string;
  cellSize?: number;
  speed?: number;
  perspective?: number;
};

export default function WowRetroGridBackground({
  className,
  color = "oklch(var(--primary))",
  lineColor = "oklch(var(--primary) / 0.2)",
  dotColor = "oklch(var(--primary) / 0.5)",
  cellSize = 50,
  speed = 0.5,
  perspective = 1000,
}: WowRetroGridBackgroundProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [dimensions, setDimensions] = useState({ width: 0, height: 0 });
  const animationRef = useRef<number>(0);
  const timeRef = useRef<number>(0);

  // Setup canvas and handle resize
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const updateSize = () => {
      const { width, height } = canvas.getBoundingClientRect();
      canvas.width = width * window.devicePixelRatio;
      canvas.height = height * window.devicePixelRatio;
      setDimensions({ width: canvas.width, height: canvas.height });
    };

    updateSize();
    window.addEventListener('resize', updateSize);
    
    return () => {
      window.removeEventListener('resize', updateSize);
      cancelAnimationFrame(animationRef.current);
    };
  }, []);

  // Animation logic
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || dimensions.width === 0) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const drawGrid = (time: number) => {
      if (!ctx) return;
      
      // Clear the canvas
      ctx.clearRect(0, 0, dimensions.width, dimensions.height);
      
      // Calculate grid parameters based on time
      const scale = Math.sin(time * 0.001) * 0.1 + 0.9;
      const offsetX = Math.sin(time * 0.0002) * dimensions.width * 0.1;
      const offsetY = Math.cos(time * 0.0003) * dimensions.height * 0.1;
      
      // Set scale origin to center
      ctx.save();
      ctx.translate(dimensions.width / 2, dimensions.height);
      ctx.scale(scale, scale);
      ctx.translate(-dimensions.width / 2, -dimensions.height);
      
      // Draw horizontal lines
      const horizonY = dimensions.height * 0.5;
      ctx.strokeStyle = lineColor;
      ctx.lineWidth = 1;
      
      // Calculate vanishing point
      const vanishingX = dimensions.width / 2 + offsetX;
      const vanishingY = horizonY;
      
      // Draw horizontal grid lines with perspective
      for (let y = horizonY; y <= dimensions.height + cellSize; y += cellSize) {
        const factor = (y - horizonY) / (dimensions.height - horizonY);
        const perspectiveWidth = dimensions.width * (1 + factor * 2);
        
        ctx.beginPath();
        ctx.moveTo(vanishingX - perspectiveWidth / 2, y);
        ctx.lineTo(vanishingX + perspectiveWidth / 2, y);
        ctx.stroke();
      }
      
      // Draw vertical grid lines with perspective
      const verticalLineCount = Math.ceil(dimensions.width / cellSize) + 4;
      for (let i = -verticalLineCount / 2; i <= verticalLineCount / 2; i++) {
        const x = vanishingX + i * cellSize;
        
        ctx.beginPath();
        ctx.moveTo(x, horizonY);
        ctx.lineTo(x + (x - vanishingX) * 2, dimensions.height);
        ctx.stroke();
      }
      
      // Draw horizon line
      ctx.beginPath();
      ctx.moveTo(0, horizonY);
      ctx.lineTo(dimensions.width, horizonY);
      ctx.stroke();
      
      // Add moving dots at intersections for extra effect
      ctx.fillStyle = dotColor;
      for (let y = horizonY; y <= dimensions.height + cellSize; y += cellSize) {
        const factor = (y - horizonY) / (dimensions.height - horizonY);
        const perspectiveWidth = dimensions.width * (1 + factor * 2);
        
        for (let i = -verticalLineCount / 2; i <= verticalLineCount / 2; i++) {
          const baseX = vanishingX + i * cellSize;
          const perspectiveX = baseX + (baseX - vanishingX) * factor;
          
          // Moving dots
          const dotMovement = Math.sin(time * 0.001 + i + y * 0.1) * cellSize * 0.25;
          
          ctx.beginPath();
          ctx.arc(
            perspectiveX + dotMovement, 
            y, 
            2 + factor * 2, 
            0, 
            Math.PI * 2
          );
          ctx.fill();
        }
      }
      
      ctx.restore();
    };

    // Animation loop
    const animate = (timestamp: number) => {
      if (!timeRef.current) timeRef.current = timestamp;
      const elapsed = timestamp - timeRef.current;
      
      // Adjust time based on speed
      timeRef.current = timestamp - (elapsed * (1 - speed));
      
      drawGrid(timestamp * speed);
      animationRef.current = requestAnimationFrame(animate);
    };

    animationRef.current = requestAnimationFrame(animate);
    
    return () => {
      cancelAnimationFrame(animationRef.current);
    };
  }, [dimensions, cellSize, lineColor, dotColor, speed]);

  return (
    <motion.div 
      className={cn("absolute inset-0 overflow-hidden -z-10", className)}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 1 }}
    >
      <canvas 
        ref={canvasRef} 
        className="w-full h-full"
        style={{ 
          backgroundColor: color,
          perspective: `${perspective}px`
        }}
      />
    </motion.div>
  );
}
