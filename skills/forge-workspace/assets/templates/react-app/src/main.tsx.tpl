import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { createBrowserRouter } from 'react-router';
import { RouterProvider } from 'react-router/dom';
import { AboutPage, createNote, ErrorPage, Layout, loadNotes, NotesPage } from './app.js';
import './style.css';

const router = createBrowserRouter([
  {
    Component: Layout,
    children: [
      {
        index: true,
        loader: loadNotes,
        action: createNote,
        Component: NotesPage,
        ErrorBoundary: ErrorPage,
      },
      { path: 'about', Component: AboutPage },
    ],
  },
]);

const root = document.getElementById('root');
if (!root) throw new Error('页面缺少根节点');
createRoot(root).render(
  <StrictMode>
    <RouterProvider router={router} />
  </StrictMode>,
);
