"""Generate documentation only, from the canonical DDL. Requires Pillow for PNG/PDF."""
from pathlib import Path
import re
import json
import hashlib
import html
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
DDL = ROOT / 'database/dbms12-compact/01_schema.sql'
sql = DDL.read_text(encoding='utf-8-sig')
tables = {}
for name, body in re.findall(r'CREATE TABLE dbo\.\[(\w+)\] \((.*?)\n\);', sql, re.S):
    cols = []
    for line in body.splitlines():
        m = re.match(r'\s*\[(\w+)\]\s+(\w+(?:\([\d,]+\))?).*?\b(NOT NULL|NULL)\b', line)
        if m:
            cols.append({'name': m[1], 'type': m[2], 'nullable': m[3] == 'NULL'})
    pk = re.search(r'PRIMARY KEY \((.*?)\)', body)[1]
    uniques = re.findall(r'\bUNIQUE \((.*?)\)', body)
    tables[name] = {'columns': cols, 'pk': re.findall(r'\[(\w+)\]', pk),
                    'unique': [re.findall(r'\[(\w+)\]', u) for u in uniques]}
fks = []
for m in re.finditer(r'ALTER TABLE dbo\.\[(\w+)\].*?CONSTRAINT \[(\w+)\] FOREIGN KEY \(\[(\w+)\]\) REFERENCES dbo\.\[(\w+)\] \(\[(\w+)\]\)', sql):
    fks.append(dict(child=m[1], constraint=m[2], column=m[3], parent=m[4], target=m[5], id=f'R{len(fks)+1:02}'))
assert len(tables) == 12
assert sum(len(t['columns']) for t in tables.values()) == 99
assert len(fks) == 19
for f in fks:
    t = tables[f['child']]
    f['nullable'] = next(c['nullable'] for c in t['columns'] if c['name'] == f['column'])
    f['unique'] = [f['column']] in t['unique'] or f['column'] == 'current_grade_operation_id'
    assert f['target'] in [c['name'] for c in tables[f['parent']]['columns']]
    assert [f['target']] == tables[f['parent']]['pk'] or [f['target']] in tables[f['parent']]['unique']
assert {f['id'] for f in fks if f['nullable']} == {'R06','R11','R16','R17'}
assert {f['id'] for f in fks if f['unique']} == {'R06','R07','R14','R15','R19'}

def keys(name, c):
    t = tables[name]
    return [k for k, yes in [('PK', c['name'] in t['pk']),
                            ('FK', any(f['child']==name and f['column']==c['name'] for f in fks)),
                            ('UK', [c['name']] in t['unique'] or c['name']=='current_grade_operation_id')] if yes]

# Full Mermaid ER diagram: 99 fields, all 19 physical foreign keys.
mermaid = ['erDiagram', '    direction LR']
for name, t in tables.items():
    mermaid.append(f'    {name} {{')
    for c in t['columns']:
        typ = c['type'].replace(',', '_')
        k = ','.join(keys(name, c))
        note = 'NULL' if c['nullable'] else 'NOT NULL'
        if c['name'] == 'current_grade_operation_id': note += '; filtered UNIQUE when non-NULL'
        # Mermaid UK marks the physical filtered uniqueness; note explains NULL semantics.
        mermaid.append(f'        {typ} {c["name"]} {k} "{note}"')
    mermaid.append('    }')
for f in fks:
    left = '|o' if f['nullable'] else '||'
    right = 'o|' if f['unique'] else 'o{'
    mermaid.append(f'    {f["parent"]} {left}..{right} {f["child"]} : "{f["id"]} {f["column"]}"')
(OUT/'DBMS12-relations.mmd').write_text('\n'.join(mermaid)+'\n', encoding='utf-8')

W,H = 3440,2480
BW,HEAD,RH = 680,78,27
positions = {
    'Account':(100,240), 'Course':(940,240), 'Class':(1780,240), 'Schedule':(2620,240),
    'AuthSession':(100,1060), 'Registration':(940,1060), 'StudentClassAssignment':(1780,1060), 'Attendance':(2620,1060),
    'AuditLog':(100,1790), 'Invoice':(940,1790), 'ReplayOperation':(1780,1790), 'GradeReport':(2620,1790)
}
heights = {n:HEAD+len(t['columns'])*RH+18 for n,t in tables.items()}
# Coordinates for orthogonal routes use the empty corridors between cards.
def port(n, side, frac=.5):
    x,y=positions[n]; h=heights[n]
    return {'L':(x,y+h*frac),'R':(x+BW,y+h*frac),'T':(x+BW*frac,y),'B':(x+BW*frac,y+h)}[side]
def route(parent, child, ps, cs, via, pf=.5, cf=.5):
    return [port(parent,ps,pf), *via, port(child,cs,cf)]
routes = [
    route('Account','AuthSession','B','T',[(440,920)],.5,.5),
    route('Account','Registration','R','L',[(850,500),(850,1170)],.43,.43),
    route('Course','Registration','B','T',[],.5,.5),
    route('Course','Class','R','L',[(1700,430)],.5,.5),
    route('Account','Class','T','T',[(400,175),(2100,175)],.44,.47),
    route('AuditLog','Class','R','L',[(820,1930),(820,970),(1720,970),(1720,490)],.4,.7),
    route('Registration','StudentClassAssignment','R','L',[(1700,1195)],.53,.53),
    route('Class','StudentClassAssignment','B','T',[],.5,.5),
    route('Account','StudentClassAssignment','R','T',[(875,670),(875,905),(2300,905)],.76,.765),
    route('Class','Schedule','R','L',[(2540,430)],.5,.5),
    route('Account','Schedule','T','T',[(300,135),(2960,135)],.294,.5),
    route('Schedule','Attendance','B','T',[],.5,.5),
    route('StudentClassAssignment','Attendance','R','L',[(2540,1200)],.53,.53),
    route('StudentClassAssignment','GradeReport','B','T',[(2120,1570),(2960,1570)],.5,.5),
    route('Registration','Invoice','B','T',[],.5,.5),
    route('Account','Invoice','L','L',[(65,580),(65,1660),(890,1660),(890,1970)],.59,.43),
    route('Account','AuditLog','L','L',[(40,430),(40,1920)],.32,.37),
    route('Account','ReplayOperation','R','T',[(805,735),(805,1620),(2120,1620)],.88,.5),
    route('AuditLog','ReplayOperation','B','B',[(440,2250),(2120,2250)],.5,.5),
]
assert len(routes)==len(fks)
# Ensure route endpoint legs are orthogonal, including differing card heights.
for pts in routes:
    i=0
    while i<len(pts)-1:
        a,b=pts[i],pts[i+1]
        if a[0]!=b[0] and a[1]!=b[1]:
            pts.insert(i+1,(b[0],a[1])); i+=1
        i+=1

im=Image.new('RGB',(W,H),'#f5f8fb'); d=ImageDraw.Draw(im)
font=lambda size,bold=False:ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf' if bold else 'C:/Windows/Fonts/arial.ttf',size)
F=font(22); SMALL=font(20); TITLE=font(43,True); TABLE=font(29,True)
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
     '<rect width="100%" height="100%" fill="#f5f8fb"/>']
def text(x,y,s,size=22,fill='#193246',bold=False):
    d.text((x,y),s,font=font(size,bold),fill=fill)
    svg.append(f'<text x="{x}" y="{y+size}" font-family="Arial,sans-serif" font-size="{size}" fill="{fill}"'+(' font-weight="700"' if bold else '')+'>'+html.escape(s)+'</text>')
def rect(box,fill,outline=None,radius=0):
    d.rounded_rectangle(box,radius,fill,outline,width=2)
    x,y,x2,y2=box
    svg.append(f'<rect x="{x}" y="{y}" width="{x2-x}" height="{y2-y}" rx="{radius}" fill="{fill}" stroke="{outline or fill}"/>')
text(100,40,'DBMS12 • LƯỢC ĐỒ QUAN HỆ',43,bold=True)
text(100,96,'12 bảng  /  99 cột  /  12 khóa chính  /  19 khóa ngoại  •  Nguồn: 01_schema.sql  •  22/10/2026',23)
text(100,2310,'PK = khóa chính   |   FK = khóa ngoại   |   UK = duy nhất một cột   |   ? = cho phép NULL',23,bold=True)
text(100,2350,'Mũi tên: bảng con → bảng cha. R01–R19 đối chiếu bảng quan hệ trong DBMS12-relations.md.',23)
text(100,2390,'UNIQUE ghép: Attendance(schedule_id, class_assignment_id); ReplayOperation(actor_account_id, action_code, request_id).',22)
text(100,2425,'* Class.current_grade_operation_id: UNIQUE khi khác NULL. Một FINAL_EXAM/lớp được bảo vệ bằng filtered UNIQUE index.',22)
colors=[]
for f,pts in zip(fks,routes):
    color='#798b9b' if f['parent']=='Account' else '#217b78'
    if f['parent']=='AuditLog':color='#a06125'
    colors.append(color)
    d.line(pts,fill=color,width=3)
    svg.append('<polyline points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="none" stroke="{color}" stroke-width="3"/>')
    a,b=pts[0],pts[1]
    dx,dy=b[0]-a[0],b[1]-a[1]; length=(dx*dx+dy*dy)**.5
    ux,uy=dx/length,dy/length
    tri=[a,(a[0]+ux*15-uy*7,a[1]+uy*15+ux*7),(a[0]+ux*15+uy*7,a[1]+uy*15-ux*7)]
    d.polygon(tri,fill=color)
    svg.append('<polygon points="'+' '.join(f'{x},{y}' for x,y in tri)+f'" fill="{color}"/>')
    # Relation badge on the longest free segment; FK rows identify exact columns.
    segments=list(zip(pts,pts[1:])); a,b=max(segments,key=lambda p:abs(p[0][0]-p[1][0])+abs(p[0][1]-p[1][1]))
    x,y=(a[0]+b[0])/2,(a[1]+b[1])/2
    rect((x-26,y-15,x+30,y+16),'#f5f8fb')
    text(x-22,y-13,f['id'],20,fill=color,bold=True)
for name,t in tables.items():
    x,y=positions[name];h=heights[name]
    infrastructure=name in ('Account','AuthSession','AuditLog','ReplayOperation')
    c='#324f68' if infrastructure else '#086d68'
    rect((x+5,y+6,x+BW+5,y+h+6),'#e1e8ef',radius=12)
    rect((x,y,x+BW,y+h),'#ffffff','#c7d5df',12)
    rect((x,y,x+BW,y+HEAD),c,radius=10)
    text(x+20,y+13,name,29,fill='#ffffff',bold=True)
    text(x+20,y+49,f'{len(t["columns"])} cột',19,fill='#dbeaf0')
    for i,col in enumerate(t['columns']):
        yy=y+HEAD+i*RH+5
        ks=keys(name,col)
        mark='/'.join(ks)
        if col['name']=='current_grade_operation_id':mark+='*'
        text(x+15,yy,mark,18,fill='#0c7773',bold=True)
        text(x+125,yy,col['name']+(' ?' if col['nullable'] else ''),21,bold='PK' in ks)
        text(x+BW-164,yy,col['type'],19,fill='#617586')
im.save(OUT/'DBMS12-relations.png')
im.save(OUT/'DBMS12-relations.pdf',resolution=180)
(OUT/'DBMS12-relations.svg').write_text('\n'.join(svg+['</svg>']),encoding='utf-8')

# Uncompressed diagrams.net XML; all 12 cards and 19 connectors remain editable.
mx=ET.Element('mxfile',host='app.diagrams.net',version='24.7.17')
diagram=ET.SubElement(mx,'diagram',id='dbms12',name='DBMS12 - 12 tables')
model=ET.SubElement(diagram,'mxGraphModel',dx=str(W),dy=str(H),grid='1',gridSize='10',page='1',pageWidth=str(W),pageHeight=str(H))
root=ET.SubElement(model,'root');ET.SubElement(root,'mxCell',id='0');ET.SubElement(root,'mxCell',id='1',parent='0')
for name,t in tables.items():
    rows=[]
    for col in t['columns']:
        key='/'.join(keys(name,col)); nullable=' ?' if col['nullable'] else ''
        rows.append(html.escape(f'{key:8} {col["name"]}{nullable} : {col["type"]}'))
    value='<b>'+name+'</b><hr/>'+'<br/>'.join(rows)
    cell=ET.SubElement(root,'mxCell',id=name,value=value,style='rounded=1;whiteSpace=wrap;html=1;align=left;verticalAlign=top;spacing=16;fontFamily=Courier New;fontSize=20;fillColor=#ffffff;strokeColor=#086d68;',vertex='1',parent='1')
    x,y=positions[name]; ET.SubElement(cell,'mxGeometry',x=str(x),y=str(y),width=str(BW),height=str(heights[name]),attrib={'as':'geometry'})
for f,pts,color in zip(fks,routes,colors):
    cell=ET.SubElement(root,'mxCell',id=f['id'],value=f'{f["id"]}: {f["column"]}',edge='1',parent='1',source=f['child'],target=f['parent'],style=f'edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;strokeColor={color};fontSize=17;labelBackgroundColor=#ffffff;')
    geo=ET.SubElement(cell,'mxGeometry',relative='1',attrib={'as':'geometry'})
    arr=ET.SubElement(geo,'Array',attrib={'as':'points'})
    for x,y in reversed(pts[1:-1]):ET.SubElement(arr,'mxPoint',x=str(x),y=str(y))
ET.indent(mx)
ET.ElementTree(mx).write(OUT/'DBMS12-relations.drawio',encoding='utf-8',xml_declaration=True)

lines=['# Lược đồ quan hệ DBMS12','',
       'Sinh từ `../../database/dbms12-compact/01_schema.sql`, ngày 22/10/2026. Đúng 12 bảng, 99 cột, 12 PK và 19 FK. Chỉ mô tả schema hiện tại; không thay đổi database.','',
       '![Lược đồ đầy đủ](DBMS12-relations.png)','',
       'Ảnh PNG và PDF chứa đủ 99 cột. SVG phóng to không vỡ nét; file `.drawio` mở bằng diagrams.net để chỉnh vị trí; `.mmd` chứa ERD Mermaid đầy đủ. Mũi tên trong ảnh/drawio đi từ FK ở bảng con tới khóa được tham chiếu ở bảng cha. Mermaid dùng ký pháp chân quạ.','',
       'PK: khóa chính; FK: khóa ngoại; UK: UNIQUE một cột; `?`: NULL. UK* của Class là filtered UNIQUE khi khác NULL. Trong Mermaid, dấu phẩy trong kiểu decimal được đổi thành `_` để parser đọc được, ví dụ `decimal(5_2)` nghĩa là SQL `decimal(5,2)`.','',
       '## 19 quan hệ vật lý','',
       '|Mã|Khóa ngoại (con)|Khóa đích (cha)|Số cha / mỗi con|Số con / mỗi cha|',
       '|---|---|---|---|---|']
for f in fks:
    lines.append(f'|{f["id"]}|`{f["child"]}.{f["column"]}`|`{f["parent"]}.{f["target"]}`|'+('0..1' if f['nullable'] else '1')+'|'+('0..1' if f['unique'] else '0..N')+'|')
lines += ['', '## Ràng buộc cần giải thích trong báo cáo', '',
    '- Account dùng chung cho 7 vai trò. `student_account_id` và `teacher_account_id` cùng tham chiếu Account; trigger/SQL kiểm đúng vai trò, FK đơn thuần không phân biệt vai trò.',
    '- Registration là thực thể nối học viên với Course, có trạng thái riêng; không có UNIQUE toàn cặp student/course. Nghiệp vụ ngăn trùng hồ sơ chưa kết thúc.',
    '- Registration → Invoice và Registration → StudentClassAssignment: 1 → 0..1 do FK NOT NULL + UNIQUE. Invoice chỉ có khi duyệt; assignment chỉ có khi đủ điều kiện xếp lớp.',
    '- StudentClassAssignment → GradeReport: DDL là 1 → 0..1. `usp_PlacementCreate` tạo report stub cùng transaction với assignment trong luồng ứng dụng; không đổi ký hiệu vật lý thành bắt buộc 1–1.',
    '- Attendance có UNIQUE(schedule_id, class_assignment_id). Trigger bảo vệ buổi và assignment thuộc cùng lớp; không có FK trực tiếp Attendance → Class.',
    '- ReplayOperation có UNIQUE(actor_account_id, action_code, request_id) và UNIQUE(operation_id). AuditLog → ReplayOperation là 1 → 0..1.',
    '- Class.current_grade_operation_id tham chiếu **AuditLog.operation_id (UK)**, không phải audit_id (PK). Filtered UNIQUE khiến một operation được tối đa một Class tham chiếu.',
    '- AuditLog.root_entity_id là tham chiếu đa loại theo action, được guard SQL/trigger; không phải FK vật lý nên không vẽ thêm đường FK.',
    '- Schedule có filtered UNIQUE(class_id) chỉ khi schedule_type = FINAL_EXAM; mỗi lớp tối đa một lịch thi cuối khóa, vẫn có nhiều LESSON.',
    '- Tất cả 19 FK có ON DELETE NO ACTION và ON UPDATE NO ACTION. Không có cascade.',
    '- Tổng điểm/đạt, trạng thái thanh toán/công nợ, trạng thái bảng điểm được suy ra; không thêm cột total_score/passed hoặc bảng Role/Payment/Band/Program.',
    '', '## Biểu diễn quan hệ đủ thuộc tính', '',
    'Dấu **đậm** là PK, `→` là FK; kiểu/nullability xem ảnh hoặc Mermaid.', '']
for name,t in tables.items():
    cols=[]
    for col in t['columns']:
        s=f'`{col["name"]}`'
        if col['name'] in t['pk']:s='**'+s+'**'
        for f in fks:
            if f['child']==name and f['column']==col['name']:s+=f' → {f["parent"]}.{f["target"]}'
        cols.append(s)
    lines.append(f'- **{name}** ('+', '.join(cols)+').')
lines += ['', '## ERD Mermaid', '', '```mermaid', *mermaid, '```', '']
(OUT/'DBMS12-relations.md').write_text('\n'.join(lines),encoding='utf-8')

# Validate generated document structure and record reproducible source identity.
assert len(ET.parse(OUT/'DBMS12-relations.drawio').findall('.//mxCell[@vertex="1"]'))==12
assert len(ET.parse(OUT/'DBMS12-relations.drawio').findall('.//mxCell[@edge="1"]'))==19
ET.parse(OUT/'DBMS12-relations.svg')
with Image.open(OUT/'DBMS12-relations.png') as pic:assert pic.size==(W,H)
receipt={'date':'2026-10-22','scope':'DDL-derived relational diagram only','tables':12,'columns':99,'primaryKeys':12,'foreignKeys':19,
         'schemaSha256':hashlib.sha256(DDL.read_bytes()).hexdigest().upper(),
         'checks':['DDL counts and FK target keys','19 relationship cardinalities from NULL/UNIQUE','drawio 12 vertices/19 edges','SVG XML parse','PNG dimensions'],
         'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest().upper() for p in sorted(OUT.glob('DBMS12-relations.*'))}}
(ROOT/'docs/evidence/relational-diagram.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in receipt.items() if k!='files'},ensure_ascii=False))
