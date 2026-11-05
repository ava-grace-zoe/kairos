import { z } from 'zod';

export const CreateNoteSchema = z.object({ title: z.string().trim().min(1).max(120) }).strict();
export const NoteSchema = z.object({
  id: z.string().uuid(),
  title: z.string(),
  createdAt: z.string().datetime(),
});
export const NotesSchema = z.array(NoteSchema);
export type CreateNote = z.infer<typeof CreateNoteSchema>;
export type Note = z.infer<typeof NoteSchema>;
