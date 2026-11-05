/** Split trusted schema/dump SQL, preserving semicolons inside quoted values. No DELIMITER/procedure support. */
export function splitSqlStatements(sql: string): string[] {
  const statements: string[] = []; let statement = ''; let quote = ''; let lineComment = false; let blockComment = false;
  for (let i=0;i<sql.length;i++) {
    const c=sql[i], next=sql[i+1];
    if (lineComment) { if(c==='\n'){lineComment=false;statement+='\n';} continue; }
    if (blockComment) { if(c==='*'&&next==='/'){blockComment=false;i++;statement+=' ';} continue; }
    if (quote) {
      statement+=c;
      if(c==='\\'&&next){statement+=next;i++;}
      else if(c===quote){if(next===quote){statement+=next;i++;}else quote='';}
      continue;
    }
    if(c==='-'&&next==='-'&&/\s/.test(sql[i+2]||' ')){lineComment=true;i++;continue;}
    if(c==='#'){lineComment=true;continue;}
    if(c==='/'&&next==='*'){blockComment=true;i++;continue;}
    if(c==="'"||c==='"'||c==='`'){quote=c;statement+=c;continue;}
    if(c===';'){if(statement.trim())statements.push(statement.trim());statement='';}
    else statement+=c;
  }
  if(quote||blockComment)throw new Error('Unterminated SQL quote/comment');
  if(statement.trim())statements.push(statement.trim());
  return statements;
}
