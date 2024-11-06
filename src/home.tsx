"use client"

import React, { useRef, useMemo } from "react"
import { Canvas, useFrame, extend, Object3DNode, useThree } from "@react-three/fiber"
import {
    PerspectiveCamera,
    Text,
    Text3D,
    Effects,
    OrbitControls,
    Float,
    useMatcapTexture,
} from "@react-three/drei"
import * as THREE from "three"
import { UnrealBloomPass } from "three/addons/postprocessing/UnrealBloomPass.js"

extend({ UnrealBloomPass })

declare module "@react-three/fiber" {
    interface ThreeElements {
        unrealBloomPass: Object3DNode<UnrealBloomPass, typeof UnrealBloomPass>
    }
}

// Custom shader for the portal effect
const portalVertexShader = `
  varying vec2 vUv;
  varying vec3 vPosition;
  
  void main() {
    vUv = uv;
    vPosition = position;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
`
const portalFragmentShader = `
  uniform float time;
  varying vec2 vUv;
  
  // Improved noise function (unchanged)
  vec2 hash2(vec2 p) {
    p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
  }

  float noise(vec2 p) {
    const float K1 = 0.366025404;
    const float K2 = 0.211324865;
    
    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;
    
    vec3 h = max(0.5 - vec3(dot(a,a), dot(b,b), dot(c,c)), 0.0);
    vec3 n = h * h * h * h * vec3(dot(a,hash2(i+0.0)), dot(b,hash2(i+o)), dot(c,hash2(i+1.0)));
    
    return dot(n, vec3(70.0));
  }
  
  void main() {
    vec2 uv = vUv - 0.5;
    
    // Create blob-like distortion
    float distortion = noise(uv * 3.0 + time * 0.2) * 0.2;
    uv += distortion;
    
    float radius = length(uv);
    
    // Base color (purple)
    vec3 baseColor = vec3(0.3, 0.0, 0.3);
    
    // Create animated noise pattern for color variation
    float noiseValue = noise(uv * 5.0 + time * 0.3) * 0.5 + 0.5;
    
    // Create main circle with soft, distorted edges
    float circle = smoothstep(0.5 + distortion, 0.48 + distortion, radius);
    
    // Create subtle pulsing effect
    float pulse = sin(time * 2.0) * 0.05 + 0.95;
    
    // Mix colors based on noise and pulse
    vec3 color = baseColor;
    color = mix(color * 1.0, color * 3.0, noiseValue * pulse);
    
    // Add subtle color variation
    color += vec3(0.1, 0.0, 0.2) * noise(uv * 8.0 + time * 0.5);
    
    // Apply circle mask
    color *= circle;
    
    gl_FragColor = vec4(color, circle);
  }
`;

function Portal() {
    const meshRef = useRef<THREE.Mesh>(null)
    const materialRef = useRef<THREE.ShaderMaterial>(null)

    // Create shader material
    const shaderData = useMemo(
        () => ({
            uniforms: {
                time: { value: 0 },
            },
            vertexShader: portalVertexShader,
            fragmentShader: portalFragmentShader,
        }),
        []
    )

    useFrame((state) => {
        if (materialRef.current) {
            materialRef.current.uniforms.time.value = state.clock.getElapsedTime()
        }
        if (meshRef.current) {
            meshRef.current.rotation.z += 0.001
        }
    })

    return (
        <mesh ref={meshRef} position={[0, 0, 0]}>
            <circleGeometry args={[2, 64]} />
            <shaderMaterial
                ref={materialRef}
                args={[shaderData]}
                transparent
                side={THREE.DoubleSide}
            />

        </mesh>
    )
}

function Scene() {


    return (
        <>
            <ambientLight intensity={0.5} />
            <pointLight position={[10, 10, 10]} intensity={1} />
            <Portal />
            <Effects>
                <unrealBloomPass threshold={0} strength={0.7} radius={0.3} />
            </Effects>
            <OrbitControls enableZoom={false} enablePan={false} />
        </>
    )
}

export default function Component() {
    return (
        <Scene />
    )
}