import { spawn } from 'node:child_process';

export function start(command, args, options = {}) {
  const child = spawn(command, args, {
    detached: process.platform !== 'win32',
    stdio: ['ignore', 'pipe', 'pipe'],
    ...options,
  });
  let output = '';
  let error;
  child.on('error', (value) => {
    error = value;
  });
  for (const stream of [child.stdout, child.stderr])
    stream?.on('data', (chunk) => {
      output = (output + chunk.toString()).slice(-20000);
    });
  const done = new Promise((resolve) => child.once('close', (code) => resolve(code ?? 1)));
  return {
    child,
    done,
    grouped: process.platform !== 'win32' && options.detached !== false,
    output: () => error?.message ?? output,
  };
}

export async function stop(processes) {
  await Promise.all(
    processes.map((item) => {
      item.stopping ??= (async () => {
        const { child, done, grouped } = item;
        if (child.exitCode !== null || child.signalCode !== null || !child.pid) return;
        const signal = (name) => {
          try {
            process.kill(grouped ? -child.pid : child.pid, name);
          } catch (error) {
            if (error.code === 'EPERM') child.kill(name);
            else if (error.code !== 'ESRCH') throw error;
          }
        };
        signal('SIGTERM');
        const timer = setTimeout(() => signal('SIGKILL'), 5000);
        try {
          await done;
        } finally {
          clearTimeout(timer);
        }
      })();
      return item.stopping;
    }),
  );
}

export async function watchGroup(commands) {
  const processes = commands.map(([command, args]) => start(command, args, { stdio: 'inherit' }));
  const shutdown = () => {
    void stop(processes);
  };
  process.once('SIGINT', shutdown);
  process.once('SIGTERM', shutdown);
  try {
    process.exitCode = await Promise.race(processes.map((item) => item.done));
  } finally {
    await stop(processes);
  }
}
