import fs from "node:fs";
import { catalog } from "./catalog.ts";
const db = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const excluded = new Map<number,string>();
const items = catalog(db,11,excluded);
console.log(JSON.stringify({items,excluded:Object.fromEntries(excluded)}));
