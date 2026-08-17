import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import './index.css'
import App from './App.tsx'
import CustomCursor from './components/CustomCursor'
import SmoothScroll from './components/SmoothScroll'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <SmoothScroll />
      <CustomCursor />
      <App />
    </BrowserRouter>
  </StrictMode>,
)
