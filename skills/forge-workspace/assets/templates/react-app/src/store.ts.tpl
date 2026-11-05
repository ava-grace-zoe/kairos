import { create } from 'zustand';

type ViewState = { query: string; setQuery: (query: string) => void };

export const useViewStore = create<ViewState>((set) => ({
  query: '',
  setQuery: (query) => set({ query }),
}));
