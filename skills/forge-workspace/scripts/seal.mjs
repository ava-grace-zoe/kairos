import { seal } from './workspace.mjs';

const published = process.argv.includes('--published');
const version = '0.1.0';
const bundle = seal(undefined, { version, source: { repository: 'https://github.com/ava-grace-zoe/kairos', ref: `forge-workspace-v${version}`, published } });
console.log(`分发清单已更新：${bundle.version} ${bundle.digest}；远端发布标记=${published}`);
