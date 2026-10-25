// Documentation only: reads the installed source; never duplicates object definitions.
const fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'../database/dbms12-compact'),manifest=JSON.parse(fs.readFileSync(path.join(root,'manifest.json'),'utf8'));
const groups={TABLE:[],SEQUENCE:[],PROCEDURE:[],FUNCTION:[],VIEW:[],TRIGGER:[],TYPE:[]};
for(const file of manifest.installOrder){const text=fs.readFileSync(path.join(root,file),'utf8');for(const m of text.matchAll(/^CREATE(?: OR ALTER)?\s+(TABLE|SEQUENCE|PROCEDURE|FUNCTION|VIEW|TRIGGER|TYPE)\s+dbo\.\[?(\w+)\]?/gm))groups[m[1]].push({type:m[1],name:m[2],file,line:text.slice(0,m.index).split('\n').length});}
const all=Object.values(groups).flat();if(all.length!==105)throw Error('Expected105objects');
const practiceRoot=path.resolve(root,'../practice'),practiceCatalog=path.join(practiceRoot,'catalog.json');
const exercises=fs.existsSync(practiceCatalog)?JSON.parse(fs.readFileSync(practiceCatalog,'utf8')).cases:[];
function table(rows,from){return ['| Object | File định nghĩa | Chạy riêng |','|---|---|---|',...rows.map(x=>{
 const c=exercises.find(c=>c.name===x.name&&['stored-procedures','functions','views','triggers'].includes(c.group));
 const practice=c?'[Bài thực hành]('+path.relative(path.join(root,from),path.join(practiceRoot,c.file)).split(path.sep).join('/')+')':'—';
 const tick=String.fromCharCode(96);
 return '| '+tick+x.name+tick+' | ['+x.file+':'+x.line+']('+path.relative(from,x.file).split(path.sep).join('/')+'#L'+x.line+') | '+practice+' |';
})].join('\n');}
const titles={TABLE:'Bảng',SEQUENCE:'Sequence',PROCEDURE:'Stored procedure',FUNCTION:'Function',VIEW:'View',TRIGGER:'Trigger',TYPE:'Table type / TVP'};
const lines=['# Danh mục105 Database Object','','Sinh từ `manifest.installOrder` bằng `node tools/Generate-SqlStudyIndex.cjs`. Mỗi liên kết trỏ vào định nghĩa source thật; không có bản SQL sao chép để học. Một số file chứa nhiều object để giữ nguyên thứ tự/phụ thuộc cài đặt.','','[Bắt đầu ở README](README.md) · [Học transaction](../../docs/study/SQL_TRANSACTIONS.md)',''];
for(const [kind,rows]of Object.entries(groups))lines.push('## '+titles[kind]+' — '+rows.length,'',table(rows,''),'');
fs.writeFileSync(path.join(root,'OBJECT_INDEX.md'),lines.join('\n'));
const folderGroups={tables:[...groups.TABLE,...groups.SEQUENCE],'stored-procedures':groups.PROCEDURE,functions:groups.FUNCTION,views:groups.VIEW,triggers:groups.TRIGGER,types:groups.TYPE};
for(const [folder,rows]of Object.entries(folderGroups)){
 const extra=folder==='stored-procedures'?'61 SP: `core/` chứa11 SP chính, `operations/` chứa45 SP còn lại, `infrastructure/` chứa5 helper. Transaction thật nằm trong từng SP theo D15.':folder==='tables'?'12 bảng và1 sequence. InvoiceNumberSequence nằm đầu schema trước các bảng dùng DEFAULT; PK/FK/CHECK/index nằm cùng DDL bảng.':folder==='functions'?'7 function:6 trong02_functions.sql và fn_ValidScore trong06_score_validation.sql.':`${rows.length} object trong nhóm này.`;
 fs.writeFileSync(path.join(root,folder,'README.md'),'# '+folder+'\n\n'+extra+'\n\n[Bản đồ chung](../README.md) · [Tất cả object](../OBJECT_INDEX.md)\n\n'+table(rows,folder)+'\n');
}
console.log('Generated105object index and6folder guides.');
