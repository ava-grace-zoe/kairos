import { CreateNoteSchema, NotesSchema } from '@__SCOPE__/contracts';
import {
  type ActionFunctionArgs,
  Form,
  Link,
  Outlet,
  useActionData,
  useLoaderData,
  useNavigation,
  useRouteError,
} from 'react-router';
import { NotesList } from './notes-list.js';

export async function loadNotes() {
  const response = await fetch('/api/notes');
  if (!response.ok) throw new Error('暂时无法加载记录，请稍后重试。');
  return NotesSchema.parse(await response.json());
}

export async function createNote({ request }: ActionFunctionArgs) {
  const form = await request.formData();
  const result = CreateNoteSchema.safeParse({ title: form.get('title') });
  if (!result.success) return { error: '请输入 1–120 字的标题。' };
  const response = await fetch('/api/notes', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(result.data),
  });
  if (!response.ok) return { error: '保存失败，请稍后重试。' };
  return { error: null };
}

export function Layout() {
  return (
    <main className="mx-auto max-w-4xl px-6 py-8 sm:px-10 sm:py-12">
      <header className="mb-20 flex items-center justify-between border-b border-slate-300 pb-6">
        <Link className="flex items-center gap-3 font-bold tracking-tight" to="/">
          <span className="rounded-lg bg-orange-700 px-2 py-1 text-white">F</span> __PROJECT_NAME__
        </Link>
        <nav className="flex gap-6 text-sm text-slate-600" aria-label="主导航">
          <Link to="/">工作台</Link>
          <Link to="/about">关于</Link>
        </nav>
      </header>
      <Outlet />
      <footer className="mt-20 border-t border-slate-300 pt-6 text-xs text-slate-500">
        __WORKSPACE__ · 从一个想法开始
      </footer>
    </main>
  );
}

export function NotesPage() {
  const notes = useLoaderData<typeof loadNotes>();
  const result = useActionData<typeof createNote>();
  const navigation = useNavigation();
  return (
    <>
      <p className="mb-4 text-xs font-semibold tracking-widest text-orange-800">你的工作空间</p>
      <h1 className="mb-4 text-4xl font-semibold tracking-tight sm:text-5xl">让想法，有处可放。</h1>
      <p className="mb-10 text-base leading-7 text-slate-600">
        记录现在的灵感，开始下一件值得做的事。
      </p>
      <Form method="post" className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <label htmlFor="note-title" className="mb-3 block text-sm font-medium">
          新的记录
        </label>
        <div className="flex flex-col gap-3 sm:flex-row">
          <input
            id="note-title"
            name="title"
            required
            maxLength={120}
            placeholder="你正在想什么？"
            className="min-w-0 flex-1 rounded-lg border border-slate-300 px-4 py-3"
          />
          <button
            type="submit"
            disabled={navigation.state !== 'idle'}
            className="rounded-lg bg-orange-800 px-6 py-3 font-medium text-white hover:bg-orange-900 disabled:opacity-50"
          >
            {navigation.state !== 'idle' ? '正在保存…' : '保存记录'}
          </button>
        </div>
        {result?.error && (
          <p role="alert" className="mt-3 text-sm text-red-700">
            {result.error}
          </p>
        )}
      </Form>
      <NotesList notes={notes} />
    </>
  );
}

export function ErrorPage() {
  const error = useRouteError();
  return (
    <section className="py-12">
      <h1 className="mb-4 text-2xl font-semibold">暂时无法打开工作台</h1>
      <p role="alert">{error instanceof Error ? error.message : '请求失败。'}</p>
      <a className="mt-6 inline-block underline" href="/">
        重新加载
      </a>
    </section>
  );
}

export function AboutPage() {
  return (
    <section>
      <h1 className="mb-4 text-3xl font-semibold">关于这个空间</h1>
      <p className="leading-8 text-slate-600">
        这是你的项目起点。记录会保存下来，你可以随时返回继续。
      </p>
    </section>
  );
}
