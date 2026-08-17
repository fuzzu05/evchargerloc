import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import './index.css'
import App from './App.tsx'
import CustomCursor from './components/CustomCursor'
import SmoothScroll from './components/SmoothScroll'
import { AuthProvider } from './context/AuthContext'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AuthProvider>
      <BrowserRouter>
        <SmoothScroll />
        <CustomCursor />
        <App />
      </BrowserRouter>
    </AuthProvider>
  </StrictMode>,
)
