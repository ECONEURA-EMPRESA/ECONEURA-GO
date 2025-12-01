import React, { useMemo, useState, useEffect, useRef, memo } from "react";
import { Link } from "react-router-dom";
import {
  Crown, Cpu, Shield, Workflow, Brain,
  ClipboardList, Megaphone, FileText, Radar,
  Bug, Gauge, ActivityIcon, Inbox, Mail, TrendingUp, FileBarChart2, CalendarDays,
  Mic, MicOff, Volume2, StopCircle, Play, Pause, Moon, Sun, LogOut, Settings, Menu,
  DollarSign, FileCheck, Clock, Send, Book, Globe, Loader
} from "lucide-react";
import { API_URL } from './config/api';
import { getApiUrl } from './utils/apiUrl';
import { ConnectAgentModal } from './components/ConnectAgentModal';
import { ChatHistory } from './components/ChatHistory';
import { LibraryPanel } from './components/LibraryPanel';
import { HITLApprovalModal } from './components/HITLApprovalModal';
import { Toaster, toast } from "sonner";
import confetti from "canvas-confetti";
import Fuse from "fuse.js";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { cx } from './utils/classnames';
import { hexToRgb, rgba } from './utils/colors';
import { LogoEconeura as BrandLogo } from './components/LogoEconeura';
import { AgentExecutionPanel } from './components/AgentExecutionPanel';
import { DepartmentSelector } from './components/DepartmentSelector';
import { DashboardMetrics } from './components/DashboardMetrics';
import { CRMExecutiveDashboard } from './components/CRMExecutiveDashboard';
import { CRMPremiumPanel } from './components/CRMPremiumPanel';
import { ErrorBoundary } from './components/ErrorBoundary';
import { NEURA_DATA as DATA, getDeptIcon, getPalette, iconForAgent, TagIcon, isComponent } from './data/neuraData';
import { NeuraChat } from './components/NeuraChat';
import { useNeuraChat } from './hooks/useNeuraChat';

// Tipos exportados
declare const process: any;

export type Agent = {
  id: string;
  title: string;
  desc: string;
  pills?: string[];
};

export interface Department {
  id: string;
  name: string;
  chips: string[];
  neura: {
    title: string;
    subtitle: string;
    tags: string[];
    value?: {
      timeSavedHoursMonth: number;
      valueEurMonth: number;
      roiPercentage: number;
      problem: string;
      solution: string;
    };
  };
  agents: Agent[];
}

type NeuraActivity = {
  id: string;
  ts: string;
  agentId: string;
  deptId: string;
  status: 'OK' | 'ERROR';
  message: string;
  executionId?: string;
};

const HeaderLogo = memo(function HeaderLogo(): React.ReactElement {
  return <BrandLogo size="xs" showText={false} darkMode className="-translate-y-[1px]" />;
});

const readVar = (winKey: string, viteKey: string, nodeKey: string, fallbackKey?: string): string | undefined => {
  const win = typeof window !== 'undefined' ? window as typeof window & Record<string, unknown> : null;
  const fromWin = win?.[winKey] as string | undefined;
  const vite = typeof import.meta !== 'undefined' ? (import.meta as any).env : null;
  const fromVite = vite?.[viteKey] as string | undefined;
  const fromFallback = fallbackKey ? vite?.[fallbackKey] as string | undefined : undefined;
  const node = typeof process !== 'undefined' ? (process as any).env : null;
  const fromNode = node?.[nodeKey] as string | undefined;
  return fromWin || fromVite || fromFallback || fromNode || undefined;
};

const isProduction = typeof window !== 'undefined' && (
  window.location.hostname.includes('vercel.app') ||
  window.location.hostname.includes('econeura.com') ||
  window.location.hostname.includes('azurestaticapps.net')
);

const env = {
  GW_URL: API_URL.replace('/api', '') || readVar('__ECONEURA_GW_URL', 'VITE_NEURA_GW_URL', 'NEURA_GW_URL', 'VITE_API_URL'),
  GW_KEY: readVar('__ECONEURA_GW_KEY', 'VITE_NEURA_GW_KEY', 'NEURA_GW_KEY'),
  LA_ID: readVar('__LA_WORKSPACE_ID', 'VITE_LA_WORKSPACE_ID', 'LA_WORKSPACE_ID'),
  LA_KEY: readVar('__LA_SHARED_KEY', 'VITE_LA_SHARED_KEY', 'LA_SHARED_KEY'),
};

const nowIso = () => new Date().toISOString();

function correlationId() {
  try {
    const crypto = globalThis.crypto;
    if (!crypto) throw new Error('no crypto');
    const rnd = crypto.getRandomValues(new Uint32Array(4));
    return Array.from(rnd).map((n) => n.toString(16)).join("");
  } catch {
    const r = () => Math.floor(Math.random() * 1e9).toString(16);
    return `${Date.now().toString(16)}${r()}${r()}`;
  }
}

function compressImage(base64Image: string, maxWidth = 800, quality = 0.7): Promise<string> {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => {
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      let { width, height } = img;
      if (width > maxWidth) {
        height = (height * maxWidth) / width;
        width = maxWidth;
      }
      canvas.width = width;
      canvas.height = height;
      ctx?.drawImage(img, 0, 0, width, height);
      resolve(canvas.toDataURL('image/jpeg', quality));
    };
    img.src = base64Image;
  });
}

function getDeptWebhook(deptId: string): string | undefined {
  const envObj = typeof import.meta !== 'undefined' ? (import.meta as any).env : {};
  const key = `VITE_MAKE_WEBHOOK_${String(deptId).toUpperCase()}`;
  const url = envObj[key] as string | undefined;
  return url && /^https:\/\/hook\.[a-z0-9.-]+\.make\.com\//i.test(url) ? url : undefined;
}

async function invokeAgent(agentId: string, _route: 'local' | 'azure' = 'azure', payload: Record<string, unknown> = {}) {
  const isLocalhost = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
  const base = isLocalhost ? 'http://localhost:3000' : (env.GW_URL || 'https://econeura-backend-prod.azurewebsites.net').replace(/\/$/, '');
  const url = `${base}/api/invoke/${agentId}`;
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Correlation-Id': correlationId() },
      body: JSON.stringify({ input: payload?.input ?? "" }),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json().catch(() => ({ ok: true, simulated: true, output: `Simulado ${agentId}` }));
  } catch {
    return { ok: true, simulated: true, output: `Simulado ${agentId}` };
  }
}

async function logActivity(row: Record<string, unknown>) {
  if (!env.LA_ID || !env.LA_KEY) return;
  const g = globalThis as typeof globalThis & {
    crypto?: Crypto & { subtle?: SubtleCrypto };
    atob?: (str: string) => string;
    btoa?: (str: string) => string;
  };
  if (!g.crypto || !g.crypto.subtle || typeof g.atob !== 'function' || typeof g.btoa !== 'function') return;
  try {
    const body = JSON.stringify([{ ...row, TimeGenerated: nowIso(), Product: 'ECONEURA', Type: 'EconeuraLogs' }]);
    const endpoint = `https://${env.LA_ID}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01`;
    if (!g.atob) return;
    const keyBytes = Uint8Array.from(g.atob(String(env.LA_KEY)), (c) => c.charCodeAt(0));
    const crypto = g.crypto.subtle;
    const k = await crypto.importKey('raw', keyBytes, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
    const date = nowIso();
    const toSign = new TextEncoder().encode(`POST\n${body.length}\napplication/json\nx-ms-date:${date}\n/api/logs`);
    const sig = await crypto.sign('HMAC', k, toSign);
    if (!g.btoa) return;
    const signature = g.btoa(String.fromCharCode(...new Uint8Array(sig)));
    await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Log-Type': 'EconeuraLogs',
        'Authorization': `SharedKey ${env.LA_ID}:${signature}`,
        'x-ms-date': date,
      },
      body,
    }).catch(() => { });
  } catch { }
}

// Polyfill for SpeechRecognition
interface SpeechRecognitionEvent extends Event { results: SpeechRecognitionResultList; resultIndex: number; }
interface SpeechRecognitionResultList { length: number; item(index: number): SpeechRecognitionResult;[index: number]: SpeechRecognitionResult; }
interface SpeechRecognitionResult { isFinal: boolean; length: number; item(index: number): SpeechRecognitionAlternative;[index: number]: SpeechRecognitionAlternative; }
interface SpeechRecognitionAlternative { transcript: string; confidence: number; }
interface SpeechRecognition extends EventTarget { continuous: boolean; interimResults: boolean; lang: string; start(): void; stop(): void; abort(): void; onresult: (event: SpeechRecognitionEvent) => void; onerror: (event: Event) => void; onend: () => void; }
declare global { interface Window { SpeechRecognition: { new(): SpeechRecognition; }; webkitSpeechRecognition: { new(): SpeechRecognition; }; } }

function LogoEconeura({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M12 2L2 7L12 12L22 7L12 2Z" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M2 17L12 22L22 17" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M2 12L12 17L22 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function FooterComponent() {
  const handleFooterClick = (section: string) => {
    switch (section) {
      case 'Privacidad': window.open('/privacy', '_blank'); break;
      case 'Cookies': window.open('/cookies', '_blank'); break;
      case 'Términoss': window.open('/terms', '_blank'); break;
      case 'Marcas registradas': window.open('/trademarks', '_blank'); break;
      case 'Cumplimiento UE': window.open('/compliance', '_blank'); break;
    }
  };
  return (
    <footer className="bg-slate-50/50 px-6 py-3 text-[10px] text-slate-500">
      <div className="flex flex-wrap items-center justify-center gap-2 font-normal">
        <span className="text-slate-600">Español (España)</span>
        <span role="separator" aria-hidden className="text-slate-300">·</span>
        <button onClick={() => handleFooterClick('Privacidad')} className="hover:text-slate-700 transition-colors hover:underline cursor-pointer bg-transparent border-0 p-0 font-normal">Tus opciones de privacidad</button>
        <span role="separator" aria-hidden className="text-slate-300">·</span>
        <button onClick={() => handleFooterClick('Cookies')} className="hover:text-slate-700 transition-colors hover:underline cursor-pointer bg-transparent border-0 p-0 font-normal">Gestionar cookies</button>
        <span role="separator" aria-hidden className="text-slate-300">·</span>
        <button onClick={() => handleFooterClick('Términoss')} className="hover:text-slate-700 transition-colors hover:underline cursor-pointer bg-transparent border-0 p-0 font-normal">Condiciones de uso</button>
        <span role="separator" aria-hidden className="text-slate-300">·</span>
        <button onClick={() => handleFooterClick('Marcas registradas')} className="hover:text-slate-700 transition-colors hover:underline cursor-pointer bg-transparent border-0 p-0 font-normal">Marcas registradas</button>
        <span role="separator" aria-hidden className="text-slate-300">·</span>
        <button onClick={() => handleFooterClick('Cumplimiento UE')} className="hover:text-slate-700 transition-colors hover:underline cursor-pointer bg-transparent border-0 p-0 font-normal">Docs cumplimiento de la UE</button>
        <span role="separator" aria-hidden className="text-slate-300">·</span>
        <span className="text-slate-600">® ECONEURA 2025</span>
      </div>
    </footer>
  );
}

interface EconeuraCockpitUser { id: string; email: string; name: string; tenantId?: string; }
interface EconeuraCockpitProps { user?: EconeuraCockpitUser; onLogout?: () => void; }

export default function EconeuraCockpit({ user, onLogout }: EconeuraCockpitProps) {
  const [activeDept, setActiveDept] = useState(DATA[0].id);
  const [orgView, setOrgView] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [q, setQ] = useState("");
  const [activity, setActivity] = useState<NeuraActivity[]>([]);
  const [chatOpen, setChatOpen] = useState(false);
  const [darkMode, setDarkMode] = useState(true);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const searchInputRef = useRef<HTMLInputElement>(null);

  const handleLogout = () => {
    if (confirm('¿Estás seguro de que quieres cerrar sesión?')) {
      localStorage.removeItem('econeura_token');
      localStorage.removeItem('econeura_user');
      sessionStorage.removeItem('econeura_token');
      sessionStorage.removeItem('econeura_user');
      if (onLogout) {
        onLogout();
      } else {
        window.location.href = '/';
      }
    }
  };

  const dept = useMemo(() => DATA.find(d => d.id === activeDept) ?? DATA[0], [activeDept]);

  const {
    chatMsgs,
    setChatMsgs,
    chatInput,
    setChatInput,
    isChatLoading,
    pendingAttachment,
    isUploadingAttachment,
    handleAttachmentUpload,
    removeAttachment,
    sendChatMessage
  } = useNeuraChat(activeDept, dept, handleLogout);

  const [listening, setListening] = useState(false);
  const [connectModalOpen, setConnectModalOpen] = useState(false);
  const [connectingAgent, setConnectingAgent] = useState<{ id: string; title: string } | null>(null);
  const [chatHistoryOpen, setChatHistoryOpen] = useState(false);
  const [libraryOpen, setLibraryOpen] = useState(false);
  const [hitlModalOpen, setHitlModalOpen] = useState(false);
  const [pendingHITL, setPendingHITL] = useState<{
    functionName: string;
    functionArgs: Record<string, unknown>;
    functionResult?: { message?: string };
    neuraName: string;
  } | null>(null);

  // Animaciones CSS
  useEffect(() => {
    const style = document.createElement('style');
    style.textContent = `
      @keyframes fadeInLeft { from { opacity: 0; transform: translateX(-30px); } to { opacity: 1; transform: translateX(0); } }
      @keyframes fadeInUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
      @keyframes floatParticle { 0%, 100% { transform: translateY(0px) translateX(0px); opacity: 0.2; } 50% { transform: translateY(-30px) translateX(15px); opacity: 0.6; } }
      @keyframes shimmer { 0% { transform: translateX(-100%) skewX(-12deg); } 100% { transform: translateX(200%) skewX(-12deg); } }
      .animate-shimmer { animation: shimmer 3s infinite; }
      .animate-fadeInLeft { animation: fadeInLeft 0.6s ease-out forwards; }
      .animate-fadeInUp { animation: fadeInUp 0.6s ease-out forwards; animation-delay: 0.1s; opacity: 0; }
    `;
    document.head.appendChild(style);
    return () => { document.head.removeChild(style); };
  }, []);

  const recognitionRef = useRef<SpeechRecognition | null>(null);

  // Keyboard shortcut
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        searchInputRef.current?.focus();
        searchInputRef.current?.select();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Voice setup
  useEffect(() => {
    try {
      const g = globalThis as typeof globalThis & { SpeechRecognition?: any; webkitSpeechRecognition?: any; };
      const SR = g.SpeechRecognition || g.webkitSpeechRecognition;
      if (SR) {
        const rec = new SR();
        rec.lang = 'es-ES';
        rec.interimResults = true;
        rec.onresult = (e: SpeechRecognitionEvent) => {
          let t = '';
          for (let i = e.resultIndex; i < e.results.length; i++) { t += e.results[i][0].transcript; }
          setChatInput(t);
        };
        rec.onend = () => setListening(false);
        recognitionRef.current = rec;
      }
    } catch { }
  }, [setChatInput]);

  function toggleListen() {
    const rec = recognitionRef.current;
    if (!rec) return;
    if (!listening) { setChatInput(''); setListening(true); try { rec.start(); } catch { } }
    else { try { rec.stop(); } catch { } }
  }

  // Fuzzy search
  const allAgentsWithDept = useMemo(() => {
    const all: Array<Agent & { deptId: string; deptName: string }> = [];
    DATA.forEach(d => {
      d.agents.forEach((a: Agent) => {
        all.push({ ...a, deptId: d.id, deptName: d.name });
      });
    });
    return all;
  }, []);

  const fuse = useMemo(() => new Fuse(allAgentsWithDept, {
    keys: ['title', 'desc', 'deptName'],
    threshold: 0.4,
    ignoreLocation: true,
    includeScore: true
  }), [allAgentsWithDept]);

  const filteredAgents = useMemo(() => {
    if (!q.trim()) return dept.agents;
    const results = fuse.search(q);
    return results.map(r => r.item);
  }, [fuse, q, dept.agents]);

  async function runAgent(a: Agent) {
    try {
      setBusyId(a.id);
      const apiUrl = getApiUrl();
      try {
        const response = await fetch(`${apiUrl}/api/neura-agents/execute/${a.id}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ input: {}, userId: null, action: 'execute', parameters: { input: `Ejecutar ${a.title}`, context: 'cockpit-execution' } })
        });
        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.error || `Error ejecutando agente: ${response.status}`);
        }
        const result = await response.json();
        setActivity(v => [{ id: correlationId(), ts: nowIso(), agentId: a.id, deptId: dept.id, status: 'OK', message: `Ejecutado exitosamente - Status: ${result.status}`, executionId: result.timestamp }, ...v]);
        confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
        toast.success(`✅ ${a.title} ejecutado exitosamente`);
        return;
      } catch (mappingError: unknown) {
        const webhook = getDeptWebhook(dept.id);
        if (webhook) {
          const controller = new AbortController();
          const timeout = setTimeout(() => controller.abort(), 10000);
          await fetch(webhook, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ agentId: a.id, deptId: dept.id, ts: nowIso(), source: 'cockpit' }),
            signal: controller.signal
          });
          clearTimeout(timeout);
          setActivity(v => [{ id: correlationId(), ts: nowIso(), agentId: a.id, deptId: dept.id, status: 'OK', message: 'Webhook Make OK' }, ...v]);
          logActivity({ AgentId: a.id, DeptId: dept.id, Status: 'OK', Type: 'Make' });
          confetti({ particleCount: 80, spread: 60, origin: { y: 0.6 } });
          toast.success(`✓ ${a.title} ejecutado exitosamente`, { description: 'Webhook Make completado', duration: 3000 });
        } else {
          throw mappingError;
        }
      }
    } catch (e: any) {
      setActivity(v => [{ id: correlationId(), ts: nowIso(), agentId: a.id, deptId: dept.id, status: 'ERROR', message: String(e?.message || 'Error') }, ...v]);
      logActivity({ AgentId: a.id, DeptId: dept.id, Status: 'ERROR' });
      toast.error(`✗ Error al ejecutar ${a.title}`, { description: String(e?.message || 'Verifica la conexión con el backend'), duration: 4000 });
    } finally {
      setBusyId(null);
    }
  }

  function startCreateAgent(deptId: string) {
    const instructions = `NEW AGENTE · ${deptId}\nCrea un agente y conéctalo a Make.\n1) Pega el Webhook de Make en backend.\n2) Define I/O y permisos.\n3) Publica.`;
    setActivity(v => [{ id: correlationId(), ts: nowIso(), agentId: 'new-agent', deptId, status: 'OK', message: 'Solicitud de creación de agente' }, ...v]);
    setChatOpen(true);
    setChatMsgs(v => [...v, { id: correlationId(), text: instructions, role: 'assistant' }]);
  }

  const DeptIconComp = getDeptIcon(dept.id);
  const pal = getPalette(dept.id);

  return (
    <>
      <Toaster position="top-right" theme={darkMode ? 'dark' : 'light'} richColors closeButton />
      <div className={`min-h-screen relative transition-colors duration-500 overflow-hidden ${darkMode ? 'bg-[#0d1117] text-slate-100' : 'bg-gradient-to-br from-slate-50 via-white to-slate-50/80 text-slate-900'}`} style={{ boxShadow: darkMode ? 'none' : 'inset 0 1px 0 rgba(255, 255, 255, 0.5)' }}>
        {darkMode && (
          <div className="absolute inset-0 overflow-hidden pointer-events-none">
            {[...Array(30)].map((_, i) => (
              <div key={i} className="absolute w-1 h-1 rounded-full" style={{ left: `${Math.random() * 100}%`, top: `${Math.random() * 100}%`, animation: `floatParticle 20s ${Math.random() * 5}s infinite ease-in-out`, background: `hsl(${200 + Math.random() * 60}, 70%, 60%)`, opacity: 0.3 + Math.random() * 0.4 }} />
            ))}
          </div>
        )}

        <div className={`relative h-20 border-b flex items-center px-8 justify-between z-20 ${darkMode ? 'border-slate-800 bg-[#161b22]' : 'border-slate-200/40 bg-gradient-to-b from-white via-white to-slate-50/30'}`} style={{ boxShadow: darkMode ? '0 4px 20px rgba(0, 0, 0, 0.3), 0 2px 8px rgba(0, 0, 0, 0.2)' : '0 2px 12px rgba(0, 0, 0, 0.06), 0 1px 3px rgba(0, 0, 0, 0.04), inset 0 1px 0 rgba(255, 255, 255, 0.8)', transform: 'translateZ(0)', transformStyle: 'preserve-3d' }}>
          <div className={`absolute inset-x-0 top-0 h-[1px] ${darkMode ? 'bg-gradient-to-r from-transparent via-emerald-500/20 to-transparent' : 'bg-gradient-to-r from-transparent via-slate-300/40 to-transparent'}`} style={{ transform: 'translateZ(1px)' }}></div>
          <div className={`absolute inset-x-0 bottom-0 h-[1px] ${darkMode ? 'bg-gradient-to-r from-transparent via-slate-700/40 to-transparent' : 'bg-gradient-to-r from-transparent via-slate-200/60 to-transparent'}`} style={{ transform: 'translateZ(-1px)' }}></div>

          <div className="flex items-center gap-3.5 group">
            <button onClick={() => setSidebarOpen(!sidebarOpen)} className={`md:hidden w-10 h-10 rounded-lg flex items-center justify-center transition-colors ${darkMode ? 'hover:bg-slate-700' : 'hover:bg-slate-100'}`} aria-label="Toggle menu"><Menu className="w-5 h-5" /></button>
            <HeaderLogo />
            <div className="relative">
              <span className="absolute top-[1.5px] left-0 text-xl font-black tracking-tight text-slate-400/40" style={{ fontFamily: '"Inter", "SF Pro Display", system-ui, -apple-system, sans-serif', letterSpacing: '-0.03em', fontWeight: 900 }} aria-hidden="true">ECONEURA</span>
              <span className={`relative text-xl font-black tracking-tight ${darkMode ? 'bg-gradient-to-r from-emerald-400 via-teal-400 to-cyan-400 bg-clip-text text-transparent' : 'text-slate-900'}`} style={{ fontFamily: '"Inter", "SF Pro Display", system-ui, -apple-system, sans-serif', letterSpacing: '-0.03em', fontWeight: 900, textShadow: darkMode ? '0 2px 8px rgba(16, 185, 129, 0.3)' : '0 2px 0 rgba(255, 255, 255, 0.9), 0 -1px 0 rgba(0, 0, 0, 0.15), 0 3px 8px rgba(0, 0, 0, 0.08)' }}>ECONEURA</span>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <div className="relative hidden sm:block">
              <input ref={searchInputRef} value={q} onChange={(e) => setQ(e.target.value)} placeholder="Buscar agentes... (Ctrl+K)" aria-label="Buscar agentes" className={`h-11 w-80 rounded-xl border px-5 pr-12 text-sm font-medium focus:outline-none transition-colors duration-200 ${darkMode ? 'border-slate-700/40 bg-slate-800/30 text-slate-200 placeholder:text-slate-500 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500/40 shadow-md' : 'border-slate-200/80 bg-slate-50/70 text-slate-900 placeholder:text-slate-400 focus:border-slate-300 hover:border-slate-300 hover:bg-slate-50 shadow-sm'}`} style={{ fontFamily: '"Inter", "SF Pro Text", system-ui, -apple-system, sans-serif' }} />
              <div className={`absolute right-4 top-1/2 -translate-y-1/2 transition-colors ${darkMode ? 'text-emerald-500/50' : 'text-slate-400'}`}><Radar className="w-[18px] h-[18px]" /></div>
              {q.trim() && (
                <div className="absolute top-full mt-2 w-full bg-white border border-slate-200 rounded-xl shadow-2xl overflow-hidden z-50 animate-fadeIn">
                  <div className="bg-gradient-to-r from-blue-50 to-slate-50 px-4 py-2 border-b border-slate-200">
                    <div className="flex items-center justify-between text-xs">
                      <span className="font-semibold text-slate-700">{filteredAgents.length} resultado{filteredAgents.length !== 1 ? 's' : ''}</span>
                      {filteredAgents.length > 0 && (<button onClick={() => setQ('')} className="text-blue-600 hover:text-blue-700 font-medium">Limpiar</button>)}
                    </div>
                  </div>
                  <div className="max-h-96 overflow-y-auto">
                    {filteredAgents.length === 0 ? (
                      <div className="px-4 py-8 text-center text-sm text-slate-500">No se encontraron agentes</div>
                    ) : (
                      <div className="divide-y divide-slate-100">
                        {filteredAgents.map((agent) => {
                          const AgentIcon = iconForAgent(agent.id);
                          return (
                            <button key={agent.id} onClick={() => { runAgent(agent); setQ(''); }} className="w-full text-left px-4 py-3 hover:bg-slate-50 transition-colors flex items-start gap-3 group">
                              <div className={`p-2 rounded-lg ${darkMode ? 'bg-slate-100' : 'bg-white'} border border-slate-200 shadow-sm group-hover:scale-110 transition-transform duration-200`}><AgentIcon className="w-4 h-4 text-slate-600" /></div>
                              <div>
                                <div className="font-medium text-slate-900 text-sm flex items-center gap-2">{agent.title} <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-slate-100 text-slate-500 font-medium border border-slate-200">{(agent as any).deptName}</span></div>
                                <div className="text-xs text-slate-500 line-clamp-1 mt-0.5">{agent.desc}</div>
                              </div>
                            </button>
                          );
                        })}
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
            <div className="h-6 w-[1px] bg-slate-200/20 mx-1"></div>
            <button onClick={() => setDarkMode(!darkMode)} className={`w-10 h-10 rounded-xl flex items-center justify-center transition-all duration-300 ${darkMode ? 'bg-slate-800 text-yellow-400 hover:bg-slate-700 hover:scale-105 hover:shadow-lg hover:shadow-yellow-400/10' : 'bg-white text-slate-600 hover:bg-slate-50 hover:text-indigo-600 hover:scale-105 shadow-sm border border-slate-200'}`} aria-label="Toggle theme">{darkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}</button>
            <button onClick={handleLogout} className={`w-10 h-10 rounded-xl flex items-center justify-center transition-all duration-300 ${darkMode ? 'bg-slate-800 text-slate-400 hover:bg-red-500/10 hover:text-red-400 hover:scale-105' : 'bg-white text-slate-600 hover:bg-red-50 hover:text-red-600 hover:scale-105 shadow-sm border border-slate-200'}`} aria-label="Logout"><LogOut className="w-5 h-5" /></button>
          </div>
        </div>

        <div className="flex h-[calc(100vh-80px)] relative z-10">
          <DepartmentSelector activeDept={activeDept} setActiveDept={setActiveDept} darkMode={darkMode} sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen} orgView={orgView} setOrgView={setOrgView} />
          <main className="flex-1 overflow-y-auto relative scroll-smooth">
            <div className="max-w-7xl mx-auto px-4 sm:px-8 py-8 space-y-8">
              <div className="animate-fadeInLeft">
                <div className="flex items-center gap-4 mb-2">
                  <div className={`p-3 rounded-2xl shadow-lg ${darkMode ? 'bg-slate-800' : 'bg-white'}`} style={{ color: pal.textHex, boxShadow: `0 10px 15px -3px ${pal.textHex}20` }}><DeptIconComp className="w-8 h-8" /></div>
                  <div>
                    <h1 className={`text-3xl font-bold tracking-tight ${darkMode ? 'text-white' : 'text-slate-900'}`}>{dept.neura.title}</h1>
                    <p className={`text-lg ${darkMode ? 'text-slate-400' : 'text-slate-500'}`}>{dept.neura.subtitle}</p>
                  </div>
                </div>
                <div className="flex flex-wrap gap-2 mt-4 ml-[76px]">
                  {dept.neura.tags.map(tag => (<span key={tag} className={`px-3 py-1 rounded-full text-xs font-medium border transition-all hover:scale-105 cursor-default ${darkMode ? 'bg-slate-800/50 border-slate-700 text-slate-300 hover:border-slate-600' : 'bg-white border-slate-200 text-slate-600 hover:border-slate-300 shadow-sm'}`}>{tag}</span>))}
                </div>
              </div>

              {dept.neura.value && (
                <div className="animate-fadeInUp" style={{ animationDelay: '0.1s' }}>
                  <DashboardMetrics dept={dept} darkMode={darkMode} />
                </div>
              )}

              <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 animate-fadeInUp" style={{ animationDelay: '0.2s' }}>
                <div className="lg:col-span-2 space-y-8">
                  <div className={`rounded-3xl border overflow-hidden relative group transition-all duration-500 ${darkMode ? 'bg-[#161b22] border-slate-800 hover:border-slate-700 hover:shadow-2xl hover:shadow-emerald-500/5' : 'bg-white border-slate-200 shadow-xl shadow-slate-200/50 hover:shadow-2xl hover:shadow-slate-200/80'}`}>
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-emerald-500 via-teal-500 to-cyan-500 opacity-80"></div>
                    <div className={`p-6 border-b flex items-center justify-between ${darkMode ? 'border-slate-800 bg-slate-800/50' : 'border-slate-100 bg-slate-50/50'}`}>
                      <div className="flex items-center gap-3">
                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${darkMode ? 'bg-emerald-500/10 text-emerald-400' : 'bg-emerald-50 text-emerald-600'}`}><Cpu className="w-5 h-5" /></div>
                        <div><h2 className={`text-lg font-bold ${darkMode ? 'text-white' : 'text-slate-900'}`}>NEURA Chat</h2><p className={`text-xs ${darkMode ? 'text-slate-400' : 'text-slate-500'}`}>Asistente IA especializado</p></div>
                      </div>
                      <div className="flex items-center gap-2">
                        <button onClick={toggleListen} className={`p-2 rounded-lg transition-all ${listening ? 'bg-red-500/20 text-red-400 animate-pulse' : darkMode ? 'hover:bg-slate-700 text-slate-400' : 'hover:bg-slate-100 text-slate-500'}`} title="Dictar por voz">{listening ? <MicOff className="w-4 h-4" /> : <Mic className="w-4 h-4" />}</button>
                        <button onClick={() => setChatHistoryOpen(true)} className={`p-2 rounded-lg transition-all ${darkMode ? 'hover:bg-slate-700 text-slate-400' : 'hover:bg-slate-100 text-slate-500'}`} title="Historial"><Clock className="w-4 h-4" /></button>
                      </div>
                    </div>
                    <div className="h-[500px] flex flex-col relative">
                      <NeuraChat
                        messages={chatMsgs}
                        input={chatInput}
                        setInput={setChatInput}
                        onSend={sendChatMessage}
                        isLoading={isChatLoading}
                        darkMode={darkMode}
                        deptId={activeDept}
                        pendingAttachment={pendingAttachment}
                        isUploadingAttachment={isUploadingAttachment}
                        onAttachmentUpload={handleAttachmentUpload}
                        onRemoveAttachment={removeAttachment}
                        onSuggestionClick={(sug) => setChatInput(sug)}
                      />
                    </div>
                  </div>

                  <div className="animate-fadeInUp" style={{ animationDelay: '0.3s' }}>
                    <AgentExecutionPanel
                      dept={dept}
                      darkMode={darkMode}
                      onRunAgent={runAgent}
                      busyId={busyId}
                      onCreateAgent={() => startCreateAgent(dept.id)}
                      onConnectAgent={(agent) => { setConnectingAgent(agent); setConnectModalOpen(true); }}
                    />
                  </div>
                </div>

                <div className="space-y-8 animate-fadeInUp" style={{ animationDelay: '0.4s' }}>
                  <div className={`rounded-3xl border overflow-hidden ${darkMode ? 'bg-[#161b22] border-slate-800' : 'bg-white border-slate-200 shadow-lg'}`}>
                    <div className={`p-5 border-b flex items-center justify-between ${darkMode ? 'border-slate-800' : 'border-slate-100'}`}>
                      <h3 className={`font-bold flex items-center gap-2 ${darkMode ? 'text-white' : 'text-slate-900'}`}><ActivityIcon className="w-4 h-4 text-blue-500" /> Actividad Reciente</h3>
                      <span className={`text-xs px-2 py-0.5 rounded-full ${darkMode ? 'bg-slate-800 text-slate-400' : 'bg-slate-100 text-slate-500'}`}>{activity.length}</span>
                    </div>
                    <div className="max-h-[400px] overflow-y-auto p-2 space-y-1 custom-scrollbar">
                      {activity.length === 0 ? (
                        <div className={`text-center py-8 ${darkMode ? 'text-slate-500' : 'text-slate-400'}`}><p className="text-sm">No hay actividad reciente</p></div>
                      ) : (
                        activity.map((act) => (
                          <div key={act.id} className={`p-3 rounded-xl border text-sm transition-all hover:scale-[1.02] ${act.status === 'OK' ? (darkMode ? 'bg-emerald-500/5 border-emerald-500/10' : 'bg-emerald-50 border-emerald-100') : (darkMode ? 'bg-red-500/5 border-red-500/10' : 'bg-red-50 border-red-100')}`}>
                            <div className="flex justify-between items-start mb-1">
                              <span className={`font-semibold ${act.status === 'OK' ? (darkMode ? 'text-emerald-400' : 'text-emerald-700') : (darkMode ? 'text-red-400' : 'text-red-700')}`}>{act.agentId}</span>
                              <span className={`text-[10px] ${darkMode ? 'text-slate-500' : 'text-slate-400'}`}>{new Date(act.ts).toLocaleTimeString()}</span>
                            </div>
                            <p className={`${darkMode ? 'text-slate-300' : 'text-slate-600'}`}>{act.message}</p>
                          </div>
                        ))
                      )}
                    </div>
                  </div>

                  <div className={`rounded-3xl border overflow-hidden ${darkMode ? 'bg-[#161b22] border-slate-800' : 'bg-white border-slate-200 shadow-lg'}`}>
                    <div className={`p-5 border-b ${darkMode ? 'border-slate-800' : 'border-slate-100'}`}>
                      <h3 className={`font-bold flex items-center gap-2 ${darkMode ? 'text-white' : 'text-slate-900'}`}><Book className="w-4 h-4 text-purple-500" /> Biblioteca NEURA</h3>
                    </div>
                    <div className="p-5">
                      <p className={`text-sm mb-4 ${darkMode ? 'text-slate-400' : 'text-slate-600'}`}>Accede a documentos, guías y recursos de conocimiento.</p>
                      <button onClick={() => setLibraryOpen(true)} className={`w-full py-2.5 rounded-xl text-sm font-medium transition-all ${darkMode ? 'bg-slate-800 text-white hover:bg-slate-700' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'}`}>Abrir Biblioteca</button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <FooterComponent />
          </main>
        </div>

        {connectModalOpen && connectingAgent && (
          <ConnectAgentModal isOpen={connectModalOpen} onClose={() => { setConnectModalOpen(false); setConnectingAgent(null); }} agent={connectingAgent} darkMode={darkMode} />
        )}

        {chatHistoryOpen && (
          <ChatHistory isOpen={chatHistoryOpen} onClose={() => setChatHistoryOpen(false)} darkMode={darkMode} onSelectChat={(chat) => { setChatMsgs(chat.messages); setChatHistoryOpen(false); }} />
        )}

        {libraryOpen && (
          <LibraryPanel isOpen={libraryOpen} onClose={() => setLibraryOpen(false)} darkMode={darkMode} />
        )}

        {hitlModalOpen && pendingHITL && (
          <HITLApprovalModal isOpen={hitlModalOpen} onClose={() => { setHitlModalOpen(false); setPendingHITL(null); }} data={pendingHITL} onApprove={() => { toast.success("Aprobado"); setHitlModalOpen(false); }} onReject={() => { toast.error("Rechazado"); setHitlModalOpen(false); }} darkMode={darkMode} />
        )}
      </div>
    </>
  );
}

// Export for testing
export const __TEST_HELPERS = {
  correlationId,
  iconForAgent
};
