"""DDL-derived Chen notation; documentation only. Requires Pillow and Windows Arial."""
from pathlib import Path
import re, math, html, json, hashlib
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
ddl=ROOT/'database/dbms12-compact/01_schema.sql'
sql=ddl.read_text(encoding='utf-8-sig')
tables={}
for name,body in re.findall(r'CREATE TABLE dbo\.\[(\w+)\] \((.*?)\n\);',sql,re.S):
    cols=[m.groups() for line in body.splitlines() if (m:=re.match(r'\s*\[(\w+)\]\s+(\w+(?:\([\d,]+\))?).*?\b(NOT NULL|NULL)\b',line))]
    tables[name]={'cols':cols,'pk':re.findall(r'\[(\w+)\]',re.search(r'PRIMARY KEY \((.*?)\)',body)[1]),
                  'uq':[re.findall(r'\[(\w+)\]',s) for s in re.findall(r'\bUNIQUE \((.*?)\)',body)]}
fks=[dict(child=c,col=f,parent=p,target=t) for c,f,p,t in re.findall(r'ALTER TABLE dbo\.\[(\w+)\].*?FOREIGN KEY \(\[(\w+)\]\) REFERENCES dbo\.\[(\w+)\] \(\[(\w+)\]\)',sql)]
assert len(tables)==12 and sum(len(t['cols']) for t in tables.values())==99 and len(fks)==19
labels=['Có phiên','Đăng ký','Thuộc khóa','Có lớp','Giảng dạy','Quyết định điểm','Được xếp lớp','Có học viên','Xếp lớp','Có lịch','Xác nhận buổi','Có điểm danh','Được điểm danh','Có bảng điểm','Có hóa đơn','Thu tiền','Thực hiện','Gửi lệnh','Ghi nhận lệnh']
W,H=7200,4400
centers={n:(850+1750*col,800+1400*row) for n,col,row in [
 ('Account',0,0),('Course',1,0),('Class',2,0),('Schedule',3,0),
 ('AuthSession',0,1),('Registration',1,1),('StudentClassAssignment',2,1),('Attendance',3,1),
 ('AuditLog',0,2),('Invoice',1,2),('ReplayOperation',2,2),('GradeReport',3,2)]}
EW,EH,AX,AY=480,110,510,72
def port(name,side='T',offset=0):
    x,y=centers[name]
    return (x+offset,y-EH/2) if side=='T' else (x+offset,y+EH/2)
# All inter-entity edges use free vertical space between attribute groups.
# Each tuple: parent port, child port, horizontal corridor y, optional outside lane x.
specs=[
 ('B',0,'T',0,1510,None),('B',-150,'T',-120,1430,None),
 ('B',0,'T',0,1580,None),('T',0,'T',0,370,None),
 ('T',0,'T',-120,230,None),('T',0,'B',0,3090,1780),
 ('B',120,'T',-120,1510,None),('B',0,'T',0,1430,None),
 ('B',-75,'T',120,1350,None),('T',120,'T',0,460,None),
 ('T',120,'T',120,140,None),('B',0,'T',0,1580,None),
 ('B',0,'T',120,1660,None),('B',120,'T',0,3050,None),
 ('B',0,'T',0,2940,None),('B',75,'T',-120,2860,1660),
 ('B',150,'T',-120,2740,90),('B',0,'T',120,3160,1780),
 ('B',0,'B',0,4140,None)]
paths=[]
for i,(f,spec) in enumerate(zip(fks,specs)):
    ps,po,cs,co,lane,outer=spec
    a=port(f['parent'],ps,po); b=port(f['child'],cs,co)
    if outer is None:
        pts=[a,(a[0],lane),(b[0],lane),b]
    else:
        # Leave the parent group vertically, use a side corridor for long links.
        escape=(centers[f['parent']][1]+480 if ps=='B' else centers[f['parent']][1]-480)
        pts=[a,(a[0],escape),(outer,escape),(outer,lane),(b[0],lane),b]
    # Diamond is in the longest horizontal corridor, away from oval attributes.
    segs=[(j,p,q) for j,(p,q) in enumerate(zip(pts,pts[1:])) if p[1]==q[1] and abs(p[0]-q[0])>350]
    if segs:
        j,p,q=max(segs,key=lambda s:abs(s[1][0]-s[2][0])); mid=((p[0]+q[0])/2,p[1])
    else:
        j,p,q=max([(j,p,q) for j,(p,q) in enumerate(zip(pts,pts[1:]))],key=lambda s:abs(s[1][1]-s[2][1]));mid=(p[0],(p[1]+q[1])/2)
    # Keep diamonds clear of the parallel Account links and nearby diamonds.
    mid={0:(850,1850),5:(2100,3090),8:(3000,1350),17:(3700,3160)}.get(i,mid)
    j=next(j for j,(p,q) in enumerate(zip(pts,pts[1:])) if
           ((p[0]==q[0]==mid[0] and min(p[1],q[1])<=mid[1]<=max(p[1],q[1])) or
            (p[1]==q[1]==mid[1] and min(p[0],q[0])<=mid[0]<=max(p[0],q[0]))))
    f['id']=f'R{i+1:02}';f['label']=labels[i];f['mid']=mid;f['pts']=pts
    f['before']=pts[1:j+1];f['after']=pts[j+1:-1]
    f['parentCard']='0..1' if next(c[2] for c in tables[f['child']]['cols'] if c[0]==f['col'])=='NULL' else '1'
    f['childCard']='0..1' if [f['col']] in tables[f['child']]['uq'] or f['col']=='current_grade_operation_id' else '0..N'
    paths.append(f)

font=lambda s,b=False:ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf' if b else 'C:/Windows/Fonts/arial.ttf',s)
im=Image.new('RGB',(W,H),'white');draw=ImageDraw.Draw(im)
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>']
mx=ET.Element('mxfile',host='app.diagrams.net');dg=ET.SubElement(mx,'diagram',name='Chen - 12 entities 99 attributes')
model=ET.SubElement(dg,'mxGraphModel',page='1',pageWidth=str(W),pageHeight=str(H));root=ET.SubElement(model,'root')
ET.SubElement(root,'mxCell',id='0');ET.SubElement(root,'mxCell',id='1',parent='0')
def text(x,y,s,size=25,color='#1d3447',bold=False,center=False,underline=False):
    f=font(size,bold);width=draw.textlength(s,font=f)
    if center:x-=width/2
    draw.text((x,y),s,font=f,fill=color)
    if underline:draw.line((x,y+size+2,x+width,y+size+2),fill=color,width=2)
    svg.append(f'<text x="{x}" y="{y+size}" font-family="Arial,sans-serif" font-size="{size}" fill="{color}"'+(' font-weight="700"' if bold else '')+(' text-decoration="underline"' if underline else '')+'>'+html.escape(s)+'</text>')
def line(points,color='#8a9aa8',width=2):
    draw.line(points,fill=color,width=width)
    svg.append('<polyline points="'+' '.join(f'{x},{y}' for x,y in points)+f'" fill="none" stroke="{color}" stroke-width="{width}"/>')
def vertex(id,label,x,y,w,h,shape,fill):
    cell=ET.SubElement(root,'mxCell',id=id,value=label,vertex='1',parent='1',style=f'shape={shape};html=1;whiteSpace=wrap;fillColor={fill};strokeColor=#456575;fontSize=23;fontFamily=Arial;')
    ET.SubElement(cell,'mxGeometry',x=str(x-w/2),y=str(y-h/2),width=str(w),height=str(h),attrib={'as':'geometry'})
def edge(id,source,target,label='',points=None):
    c=ET.SubElement(root,'mxCell',id=id,edge='1',parent='1',source=source,target=target,value=label,style='endArrow=none;startArrow=none;html=1;strokeColor=#758b9b;fontSize=20;labelBackgroundColor=#ffffff;')
    g=ET.SubElement(c,'mxGeometry',relative='1',attrib={'as':'geometry'})
    if points:
        arr=ET.SubElement(g,'Array',attrib={'as':'points'})
        for x,y in points:ET.SubElement(arr,'mxPoint',x=str(x),y=str(y))

text(130,35,'DBMS12 — ERD CHEN',48,bold=True)
text(130,100,'12 thực thể • 99 thuộc tính • 19 quan hệ theo schema hiện tại',28)
text(130,4240,'Chữ nhật: thực thể  |  Hình thoi: quan hệ  |  Elip: thuộc tính  |  Gạch chân: khóa chính  |  ?: NULL',27,bold=True)
text(130,4290,'Nhãn gần thực thể cho biết số bản ghi của thực thể đó ứng với một bản ghi của thực thể còn lại. N = nhiều.',25)
text(130,4330,'Đây là biểu diễn Chen của model 12 hiện có, bao gồm cả thuộc tính kỹ thuật/session/audit. R01–R19 có bảng giải thích riêng.',25)

# Relations first so the attribute and entity outlines remain clear.
for f in paths:
    pts=f['pts'];color='#617c8d' if f['parent']=='Account' else '#197b74'
    line(pts,color,3)
    x,y=f['mid'];rw,rh=165,66
    poly=[(x-rw,y),(x,y-rh),(x+rw,y),(x,y+rh)]
    draw.polygon(poly,fill='#fff5d7',outline='#a47b2e',width=3)
    svg.append('<polygon points="'+' '.join(f'{a},{b}' for a,b in poly)+'" fill="#fff5d7" stroke="#a47b2e" stroke-width="3"/>')
    text(x,y-31,f['label'],23,center=True,bold=True)
    text(x,y+7,f['id'],20,center=True)
    # At parent and child endpoints: cardinality of that entity per other endpoint.
    for p,q,label in [(pts[0],pts[1],f['parentCard']),(pts[-1],pts[-2],f['childCard'])]:
        delta=1 if q[1]>p[1] else -1
        text(p[0]+16,p[1]+delta*80-14,label,24,bold=True)
    vertex(f['id'],f['label']+'<br/>'+f['id'],x,y,2*rw,2*rh,'rhombus','#fff5d7')
    edge(f['id']+'p',f['parent'],f['id'],f['parentCard'],f['before'])
    edge(f['id']+'c',f['id'],f['child'],f['childCard'],f['after'])

attribute_positions={}
for name,t in tables.items():
    cx,cy=centers[name];n=len(t['cols']);half=(n+1)//2
    attrs=[]
    for i,(col,typ,nullable) in enumerate(t['cols']):
        side=-1 if i<half else 1;index=i if side==-1 else i-half;count=half if side==-1 else n-half
        x=cx+side*AX;y=cy+(index-(count-1)/2)*AY
        attrs.append((col,typ,nullable,x,y))
        line([(cx+side*EW/2,cy),(x-side*230,y)],'#a5b2bc',2)
    for col,typ,nullable,x,y in attrs:
        pk=col in t['pk'];fk=any(f['child']==name and f['col']==col for f in fks)
        uq=[col] in t['uq'] or col=='current_grade_operation_id'
        color='#fff4c8' if pk else '#f2faf9'
        box=(x-230,y-30,x+230,y+30)
        draw.ellipse(box,fill=color,outline='#678590',width=2)
        svg.append(f'<ellipse cx="{x}" cy="{y}" rx="230" ry="30" fill="{color}" stroke="#678590" stroke-width="2"/>')
        label=col+(' ?' if nullable=='NULL' else '')
        text(x,y-17,label,22,bold=pk,center=True,underline=pk)
        id=name+'_'+col
        vertex(id,('<u>'+html.escape(label)+'</u>') if pk else label,x,y,460,60,'ellipse',color)
        edge(id+'_link',name,id)
        attribute_positions[id]=(x,y)
    color='#e8f3f2' if name not in ('Account','AuthSession','AuditLog','ReplayOperation') else '#eaf0f8'
    box=(cx-EW/2,cy-EH/2,cx+EW/2,cy+EH/2)
    draw.rectangle(box,fill=color,outline='#1d6866',width=3)
    svg.append(f'<rect x="{box[0]}" y="{box[1]}" width="{EW}" height="{EH}" fill="{color}" stroke="#1d6866" stroke-width="3"/>')
    text(cx,cy-20,name,27,bold=True,center=True)
    vertex(name,'<b>'+name+'</b>',cx,cy,EW,EH,'rectangle',color)
svg.append('</svg>')
(OUT/'ERD-Chen.svg').write_text('\n'.join(svg),encoding='utf-8')
im.save(OUT/'ERD-Chen.png')
ET.indent(mx);ET.ElementTree(mx).write(OUT/'ERD-Chen.drawio',encoding='utf-8',xml_declaration=True)

# PDF: overall diagram followed by 12 enlarged entity pages, preserving all 99 fields.
pages=[im]
for name in tables:
    cx,cy=centers[name]
    detail=Image.new('RGB',(1800,1040),'white');pd=ImageDraw.Draw(detail)
    pd.text((70,30),name,font=font(36,True),fill='#153b4a')
    crop=im.crop((cx-800,cy-520,cx+800,cy+520))
    detail.paste(crop,(100,0))
    # Header is placed last to keep the title outside any relationship labels.
    pd.rectangle((0,0,1800,55),fill='white');pd.text((45,8),name+' — Thuộc tính',font=font(30,True),fill='#153b4a')
    pages.append(detail)
pages[0].save(OUT/'ERD-Chen.pdf',save_all=True,append_images=pages[1:],resolution=180)

md=['# ERD Chen — DBMS12','','Owner chọn ký pháp Chen: thực thể hình chữ nhật, quan hệ hình thoi, thuộc tính hình elip. Sơ đồ bám model12 hiện có và giữ đủ99thuộc tính (kể cả cột kỹ thuật),12thực thể/19quan hệ. Không thêm thực thể Student/Teacher riêng: đó là vai trò Account.','',
    '![ERD Chen](ERD-Chen.png)','','[SVG phóng to](ERD-Chen.svg) · [PDF tổng thể và12trang phóng to](ERD-Chen.pdf) · [diagrams.net chỉnh sửa](ERD-Chen.drawio)','','## Ký hiệu','',
    '- Khóa chính được gạch chân. Dấu `?` là NULL. Elip không đánh dấu khóa ngoại vì quan hệ đã được biểu diễn bằng hình thoi; tên cột FK vẫn giữ để đủ99thuộc tính vật lý.',
    '- Nhãn gần thực thể chỉ số bản ghi của thực thể đó ứng với một bản ghi của thực thể còn lại: `1`, `0..1`, `0..N`.',
    '- Không dùng elip kép/thuộc tính đa trị hoặc hình chữ nhật kép/thực thể yếu vì schema không khai báo các loại đó. Không thêm thuộc tính tổng điểm/đạt suy ra thành cột.',
    '- Đây là biểu diễn Chen của model thực tế, có cả session/audit/replay; không tự tái thiết kế nghiệp vụ. Kiểu SQL/UK/nullability đầy đủ nằm trong ERD-full-attributes.md.',
    '', '## Quan hệ và nguồn khóa ngoại', '', '|Mã|Thực thể cha|Quan hệ|Thực thể con|Nguồn FK|Số cha/con|Số con/cha|','|---|---|---|---|---|---|---|']
for f in paths:md.append(f'|{f["id"]}|{f["parent"]}|{f["label"]}|{f["child"]}|{f["col"]} → {f["target"]}|{f["parentCard"]}|{f["childCard"]}|')
md += ['', 'Class.current_grade_operation_id tham chiếu AuditLog.operation_id (UNIQUE), không phải audit_id. UNIQUE lọc đảm bảo một operation được tối đa một Class tham chiếu. GradeReport là0..1 theoDDL; ứng dụng tạo stub cùng transaction xếp lớp. AuditLog.root_entity_id là tham chiếu theo action, không phảiFK vật lý nên không thêm hình thoi.','',
       'Nguồn: ../../database/dbms12-compact/01_schema.sql. Chỉ sinh tài liệu; không thay schema/database/runtime.','']
(OUT/'ERD-Chen.md').write_text('\n'.join(md),encoding='utf-8')
assert len(attribute_positions)==99
ET.parse(OUT/'ERD-Chen.svg')
doc=ET.parse(OUT/'ERD-Chen.drawio')
assert len(doc.findall('.//mxCell[@vertex="1"]'))==130
assert len(doc.findall('.//mxCell[@edge="1"]'))==137
receipt={'date':'2026-10-22','notation':'Chen','entities':12,'attributes':99,'relationships':19,'drawioVertices':130,'drawioEdges':137,'pdfPages':13,'schemaSha256':hashlib.sha256(ddl.read_bytes()).hexdigest().upper(),
         'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest().upper() for p in sorted(OUT.glob('ERD-Chen.*'))}}
(ROOT/'docs/evidence/erd-chen.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in receipt.items() if k!='files'},ensure_ascii=False))
