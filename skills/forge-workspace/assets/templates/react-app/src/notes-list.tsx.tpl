import type { Note } from '@__SCOPE__/contracts';
import { useViewStore } from './store.js';

export function NotesList({ notes }: { notes: Note[] }) {
  const query = useViewStore((state) => state.query);
  const setQuery = useViewStore((state) => state.setQuery);
  const visible = notes.filter((note) =>
    note.title.toLocaleLowerCase().includes(query.toLocaleLowerCase()),
  );

  return (
    <section className="mt-12" aria-label="记录列表">
      <div className="mb-5 flex flex-wrap items-center justify-between gap-4">
        <h2 className="text-xl font-semibold">
          所有记录 <span className="ml-2 text-sm font-normal text-slate-500">{notes.length}</span>
        </h2>
        <label className="flex items-center gap-3 text-sm text-slate-600">
          筛选记录
          <input
            className="rounded-lg border border-slate-300 bg-white px-3 py-2"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </label>
      </div>
      {visible.length ? (
        <ul className="grid gap-3">
          {visible.map((note) => (
            <li
              key={note.id}
              className="flex items-center justify-between gap-4 rounded-xl border border-slate-200 bg-white p-5"
            >
              <span className="break-all font-medium">{note.title}</span>
              <time className="shrink-0 text-xs text-slate-500" dateTime={note.createdAt}>
                {new Date(note.createdAt).toLocaleDateString('zh-CN')}
              </time>
            </li>
          ))}
        </ul>
      ) : (
        <p className="rounded-xl border border-dashed border-slate-300 p-10 text-center text-slate-500">
          {query ? '没有匹配的记录' : '写下第一个想法，从这里开始。'}
        </p>
      )}
    </section>
  );
}
