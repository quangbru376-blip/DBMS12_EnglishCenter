"""Prepare a complete Mermaid ERD while preserving the owner's reference relations."""
from pathlib import Path
import re
import json
import hashlib

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
REFERENCE = OUT / 'ERD-reference-keys-only.md'
DDL = ROOT / 'database/dbms12-compact/01_schema.sql'
reference = REFERENCE.read_text(encoding='utf-8-sig')
sql = DDL.read_text(encoding='utf-8-sig')
block = re.search(r'```mermaid\s*\n(.*?)```', reference, re.S)[1]
relations = [line.strip() for line in block.splitlines() if re.match(r'\s*\w+\s+[|o}{]+--[|o}{]+\s+\w+\s*:', line)]
foreign = re.findall(r'ALTER TABLE dbo\.\[(\w+)\].*?FOREIGN KEY \(\[(\w+)\]\) REFERENCES dbo\.\[(\w+)\] \(\[(\w+)\]\)', sql)
assert len(relations) == len(foreign) == 19
parsed = [re.fullmatch(r'(\w+)\s+([|o}{]+)--([|o}{]+)\s+(\w+)\s*:\s*"(\w+)"', line) for line in relations]
assert {(r[4],r[5],r[1]) for r in parsed} == {(child,col,parent) for child,col,parent,target in foreign}
tables = []
for name,body in re.findall(r'CREATE TABLE dbo\.\[(\w+)\] \((.*?)\n\);',sql,re.S):
    cols = [m.groups() for line in body.splitlines() if (m:=re.match(r'\s*\[(\w+)\]\s+(\w+(?:\([\d,]+\))?).*?\b(NOT NULL|NULL)\b',line))]
    pk = re.findall(r'\[(\w+)\]',re.search(r'PRIMARY KEY \((.*?)\)',body)[1])
    uq = [re.findall(r'\[(\w+)\]',u) for u in re.findall(r'\bUNIQUE \((.*?)\)',body)]
    tables.append((name,cols,pk,uq))
assert len(tables)==12 and sum(len(t[1]) for t in tables)==99
lines=['erDiagram'] + ['    '+re.sub(r'\bClass\b','"Class"',r) for r in relations]
for name,cols,pk,uq in tables:
    entity='"Class"' if name=='Class' else name
    lines.append(f'    {entity} {{')
    for col,typ,nullable in cols:
        marks=[]
        if col in pk: marks.append('PK')
        if any(child==name and fk==col for child,fk,parent,target in foreign): marks.append('FK')
        if [col] in uq or col=='current_grade_operation_id':marks.append('UK')
        # Mermaid does not allow commas within a type token: keep precision in comment.
        comment=[]
        if ',' in typ:comment.append(typ)
        if nullable=='NULL':comment.append('NULL')
        if col=='current_grade_operation_id':comment.append('UNIQUE when NOT NULL')
        rendered_type=typ.split('(')[0] if ',' in typ else typ
        extra=' "'+'; '.join(comment)+'"' if comment else ''
        lines.append(f'        {rendered_type} {col}'+(' '+','.join(marks) if marks else '')+extra)
    lines.append('    }')
mermaid='\n'.join(lines)+'\n'
(OUT/'ERD-full-attributes.mmd').write_text(mermaid,encoding='utf-8')
md='''# ERD — DBMS12 đầy đủ thuộc tính

Giữ nguyên thứ tự, nhãn và ký pháp chân quạ của 19 quan hệ trong file ERD.md mẫu owner cung cấp; bổ sung đủ 99 thuộc tính của 12 bảng từ DDL hiện tại. Bố cục được Mermaid tự sắp xếp theo kích thước bảng mới.

- PK: khóa chính; FK: khóa ngoại; UK: UNIQUE một cột. Không có ghi chú NULL nghĩa là NOT NULL.
- Tên "Class" được đặt trong dấu nháy để tương thích từ khóa Mermaid; tên bảng và các quan hệ không đổi.
- Với decimal, độ chính xác SQL được ghi trong cột chú thích, ví dụ decimal(18,0).
- Class.current_grade_operation_id có filtered UNIQUE khi khác NULL; FK tham chiếu AuditLog.operation_id, không phải audit_id.
- UNIQUE ghép: Attendance(schedule_id, class_assignment_id) và ReplayOperation(actor_account_id, action_code, request_id).
- Schedule có UNIQUE(class_id) chỉ với FINAL_EXAM; mỗi lớp vẫn có nhiều LESSON.
- GradeReport là 0..1 theo DDL; ứng dụng tạo report stub cùng transaction xếp lớp.
- AuditLog.root_entity_id không phải FK vật lý, không vẽ thêm đường quan hệ.

![ERD đầy đủ thuộc tính](ERD-full-attributes.png)

[SVG phóng to](ERD-full-attributes.svg) · [PDF](ERD-full-attributes.pdf) · [Mermaid source](ERD-full-attributes.mmd)

```mermaid
'''+mermaid+'```\n'
(OUT/'ERD-full-attributes.md').write_text(md,encoding='utf-8')
config={'theme':'default','fontFamily':'Arial','er':{'fontSize':16,'diagramPadding':30,'entityPadding':15,'nodeSpacing':100,'rankSpacing':100}}
(OUT/'erd-render-config.json').write_text(json.dumps(config,indent=2)+'\n',encoding='utf-8')
receipt={'date':'2026-10-22','tables':12,'columns':99,'foreignKeys':19,'referenceRelationsPreserved':True,'syntaxCompatibility':'Quote Class identifier for Mermaid parser; same entity name',
         'referenceSha256':hashlib.sha256(REFERENCE.read_bytes()).hexdigest().upper(),
         'schemaSha256':hashlib.sha256(DDL.read_bytes()).hexdigest().upper(),
         'source':'docs/diagrams/ERD-full-attributes.mmd','render':'pending'}
(ROOT/'docs/evidence/erd-full-attributes.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt))
