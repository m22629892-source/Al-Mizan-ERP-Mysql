import fs from 'node:fs';
import path from 'node:path';
import {build} from 'esbuild';
const output=path.resolve('installer/stage/app');fs.mkdirSync(output,{recursive:true});
for(const [entry,name] of [['server.ts','server.mjs'],['installer/windows/bootstrap.ts','bootstrap.mjs']]){
 await build({entryPoints:[entry],outfile:path.join(output,name),bundle:true,platform:'node',format:'esm',target:'node26',external:['vite'],banner:{js:"import { createRequire as __createRequire } from 'node:module'; const require = __createRequire(import.meta.url);"},logLevel:'info'});
}
fs.copyFileSync('src/server/schema.sql',path.join(output,'schema.sql'));
fs.cpSync('dist',path.join(output,'dist'),{recursive:true});
fs.copyFileSync('README_MYSQL_AR.md',path.join(output,'README_MYSQL_AR.md'));

// Retain the original dependency license files alongside the bundled application.
for (const file of fs.readdirSync('node_modules',{recursive:true})) {
 if (!/(^|[\\/])(licen[cs]e[^\\/]*|copying[^\\/]*|notice[^\\/]*)$/i.test(file)) continue;
 const source=path.join('node_modules',file);if(!fs.statSync(source).isFile())continue;
 const target=path.resolve('installer/stage/notices/npm',file);fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(source,target);
}
