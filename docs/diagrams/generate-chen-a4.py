"""Compact full Chen ERD for an A4 portrait page; no database operations."""
from pathlib import Path
import re, math, html, json, hashlib, heapq, sys
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
SAMPLE='--sample-style' in sys.argv
BASE='ERD-Chen-A4-sample' if SAMPLE else 'ERD-Chen-A4-portrait'
STROKE='#777777' if SAMPLE else '#333333'
DDL=ROOT/'database/dbms12-compact/01_schema.sql';sql=DDL.read_text(encoding='utf-8-sig')
tables={}
for name,body in re.findall(r'CREATE TABLE dbo\.\[(\w+)\] \((.*?)\n\);',sql,re.S):
    cols=[m.groups() for ln in body.splitlines() if (m:=re.match(r'\s*\[(\w+)\]\s+(\w+(?:\([\d,]+\))?).*?\b(NOT NULL|NULL)\b',ln))]
    tables[name]={'cols':cols,'pk':re.findall(r'\[(\w+)\]',re.search(r'PRIMARY KEY \((.*?)\)',body)[1]),'uq':[re.findall(r'\[(\w+)\]',s) for s in re.findall(r'\bUNIQUE \((.*?)\)',body)]}
fks=[dict(child=c,col=f,parent=p,target=t,id=f'R{i+1:02}') for i,(c,f,p,t) in enumerate(re.findall(r'ALTER TABLE dbo\.\[(\w+)\].*?FOREIGN KEY \(\[(\w+)\]\) REFERENCES dbo\.\[(\w+)\] \(\[(\w+)\]\)',sql))]
assert len(tables)==12 and sum(len(t['cols']) for t in tables.values())==99 and len(fks)==19
W,H=1800,2600
centers={n:(440 if c==0 else 1360,260+r*410) for r,pair in enumerate([
 ('Account','Course'),('AuthSession','Registration'),('AuditLog','Invoice'),
 ('ReplayOperation','Class'),('GradeReport','StudentClassAssignment'),('Attendance','Schedule')]) for c,n in enumerate(pair)}
slots=[(440,465),(900,465),(1360,465),(1580,1285),(1640,465),
       (1000,1285),(1000,1695),(1360,1695),(1640,1695),(1360,2105),
       (1640,2105),(900,2105),(500,2105),(220,1695),(1360,875),
       (900,875),(220,875),(1640,875),(440,1285)]
labels=['CÓ PHIÊN','ĐĂNG KÝ','THUỘC KHÓA','CÓ LỚP','GIẢNG DẠY','QUYẾT ĐỊNH ĐIỂM',
        'ĐƯỢC XẾP LỚP','CÓ HỌC VIÊN','XẾP LỚP','CÓ LỊCH','XÁC NHẬN BUỔI',
        'CÓ ĐIỂM DANH','ĐƯỢC ĐIỂM DANH','CÓ BẢNG ĐIỂM','CÓ HÓA ĐƠN','THU TIỀN','THỰC HIỆN','GỬI LỆNH','GHI NHẬN LỆNH']
EW,EH,AW,AH=240,50,270,40
RW,RH=110,35
font=lambda size,b=False:ImageFont.truetype('C:/Windows/Fonts/ARIALNB.TTF' if b else 'C:/Windows/Fonts/ARIALN.TTF',size)
if SAMPLE:font=lambda size,b=False:ImageFont.truetype('C:/Windows/Fonts/timesbd.ttf' if b else 'C:/Windows/Fonts/times.ttf',size)
shapes={};attrs=[]
for name,t in tables.items():
    cx,cy=centers[name];shapes[name]=(cx-EW/2,cy-EH/2,cx+EW/2,cy+EH/2)
    n=len(t['cols']);half=(n+1)//2
    for i,(col,typ,null) in enumerate(t['cols']):
        side=-1 if i<half else 1;j=i if side==-1 else i-half;count=half if side==-1 else n-half
        yy=(j-(count-1)/2)*44
        xx=255+30*(1-abs(yy)/(max(1,(count-1)/2*44)))
        x,y=cx+side*xx,cy+yy;id=name+'_'+col
        attrs.append(dict(id=id,entity=name,col=col,typ=typ,null=null,x=x,y=y,pk=col in t['pk']))
        shapes[id]=(x-AW/2,y-AH/2,x+AW/2,y+AH/2)
for f,(x,y),label in zip(fks,slots,labels):
    f.update(x=x,y=y,label=label)
    f['mandatory']=next(c[2]=='NOT NULL' for c in tables[f['child']]['cols'] if c[0]==f['col'])
    f['max']='1' if [f['col']] in tables[f['child']]['uq'] or f['col']=='current_grade_operation_id' else 'N'
    f['parent_range']='1' if f['mandatory'] else '0..1'
    f['child_range']='0..1' if f['max']=='1' else '0..N'
    if SAMPLE:f['label']=f['label'].capitalize()
    shapes[f['id']]=(x-RW,y-RH,x+RW,y+RH)

# Orthogonal routing around all text-bearing shapes on a 0.5 mm grid.
STEP=5;NX=W//STEP+1;NY=H//STEP+1
blocked=set()
attr_ids={a['id'] for a in attrs};relation_ids={f['id'] for f in fks}
for id,box in shapes.items():
    x0,y0,x1,y1=box
    for gx in range(max(1,math.floor((x0-7)/STEP)),min(NX-1,math.ceil((x1+7)/STEP))+1):
        for gy in range(max(1,math.floor((y0-7)/STEP)),min(NY-1,math.ceil((y1+7)/STEP))+1):
            dx=abs(gx*STEP-(x0+x1)/2)/((x1-x0)/2+7);dy=abs(gy*STEP-(y0+y1)/2)/((y1-y0)/2+7)
            inside=dx*dx+dy*dy<=1 if id in attr_ids else dx+dy<=1 if id in relation_ids else dx<=1 and dy<=1
            if inside:blocked.add((gx,gy))
use={};routed=[];portuse={}
def grid(p):return (round(p[0]/STEP),round(p[1]/STEP))
def compress(points):
    result=[]
    for p in points:
        if result and p==result[-1]:continue
        if len(result)>1 and (result[-2][0]==result[-1][0]==p[0] or result[-2][1]==result[-1][1]==p[1]):result[-1]=p
        else:result.append(p)
    return result
def route(start,end):
    a,b=grid(start),grid(end);initial=(a[0],a[1],4);queue=[(0,0,initial)];dist={initial:0};previous={};finish=None
    while queue:
        _,cost,state=heapq.heappop(queue);p=state[:2];heading=state[2]
        if cost!=dist.get(state):continue
        if p==b:finish=state;break
        for direction,(dx,dy) in enumerate(((1,0),(-1,0),(0,1),(0,-1))):
            if heading!=4 and direction==(heading^1):continue
            q=(p[0]+dx,p[1]+dy);nextstate=(q[0],q[1],direction)
            if not(1<=q[0]<NX-1 and 23<=q[1]<NY-31):continue
            if q in blocked and q not in (a,b):continue
            new=cost+1+use.get(q,0)*0.65+(10 if heading!=4 and heading!=direction else 0)
            if new<dist.get(nextstate,1e30):
                dist[nextstate]=new;previous[nextstate]=state
                heuristic=abs(q[0]-b[0])+abs(q[1]-b[1]);heapq.heappush(queue,(new+heuristic,new,nextstate))
    assert finish is not None,('No route',start,end)
    states=[finish]
    while states[-1]!=initial:states.append(previous[states[-1]])
    path=[s[:2] for s in reversed(states)]
    for p in path:use[p]=use.get(p,0)+1
    return compress([start]+[(x*STEP,y*STEP) for x,y in path]+[end])
for f in fks:
    for kind,entity in [('p',f['parent']),('c',f['child'])]:
        cx,cy=centers[entity];sign=1 if f['y']>cy else -1
        key=(entity,sign);index=portuse.get(key,0);portuse[key]=index+1
        # Keep all attachments in the clear central strip between attribute fans.
        off=[-80,-40,0,40,80,-100,100,-60,60][index]
        ep=(cx+off,cy+sign*EH/2);outside=(ep[0],ep[1]+sign*12)
        dp=(f['x']+(-RW if kind=='p' else RW),f['y']);dout=(dp[0]+(-12 if kind=='p' else 12),dp[1])
        pp=route(outside,dout)
        points=compress([ep]+pp+[dp])
        routed.append(dict(id=f['id']+kind,source=entity,target=f['id'],pts=points,double=not SAMPLE and kind=='c' and f['mandatory']))
print('Routing complete: 38 legs avoid all 130 shape bounds',flush=True)

im=Image.new('RGB',(W,H),'white');draw=ImageDraw.Draw(im)
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="180mm" height="260mm" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>']
mx=ET.Element('mxfile',host='app.diagrams.net');dg=ET.SubElement(mx,'diagram',name='Chen A4 portrait')
gm=ET.SubElement(dg,'mxGraphModel',page='1',pageWidth='2100',pageHeight='2970');root=ET.SubElement(gm,'root');ET.SubElement(root,'mxCell',id='0');ET.SubElement(root,'mxCell',id='1',parent='0')
def text(x,y,label,size=23,center=False,pk=False,bold=False):
    vietnamese=any(ord(ch)>127 for ch in label)
    ft=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf' if bold else 'C:/Windows/Fonts/arial.ttf',size) if vietnamese else font(size,bold)
    family='Arial,sans-serif' if vietnamese else 'Arial Narrow,Arial,sans-serif'
    if SAMPLE:ft=font(size,bold);family='Times New Roman,serif'
    bbox=ft.getbbox(label);width=ft.getlength(label)
    if center:x-=width/2
    yy=y-(bbox[1]+bbox[3])/2
    draw.text((x,yy),label,font=ft,fill='#111111')
    if pk:draw.line((x,y+(bbox[3]-bbox[1])/2+2,x+width,y+(bbox[3]-bbox[1])/2+2),fill='#111111',width=1)
    svg.append(f'<text x="{x}" y="{y}" dominant-baseline="central" font-family="{family}" font-size="{size}" fill="#111111"'+(' text-decoration="underline"' if pk else '')+(' font-weight="700"' if bold else '')+'>'+html.escape(label)+'</text>')
def line(pts,width=1):
    draw.line(pts,fill=STROKE,width=width)
    svg.append('<polyline points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="none" stroke="{STROKE}" stroke-width="{width}"/>')
def offset(pts,amount):
    out=[]
    for i,(x,y) in enumerate(pts):
        normals=[]
        for a,b in ([(pts[i-1],pts[i])] if i else [])+([(pts[i],pts[i+1])] if i<len(pts)-1 else []):
            dx,dy=b[0]-a[0],b[1]-a[1];ln=math.hypot(dx,dy)
            if ln:normals.append((-dy/ln,dx/ln))
        nx=sum(p[0] for p in normals);ny=sum(p[1] for p in normals);ln=math.hypot(nx,ny) or 1
        out.append((x+nx/ln*amount,y+ny/ln*amount))
    return out
def vertex(id,label,shape,fill):
    x,y,x1,y1=shapes[id]
    c=ET.SubElement(root,'mxCell',id=id,value=label,vertex='1',parent='1',style=f'shape={shape};html=1;whiteSpace=wrap;fillColor={fill};strokeColor=#333333;strokeWidth=1;fontFamily=Arial Narrow;fontSize=23;')
    if SAMPLE:c.set('style',c.get('style').replace('fontFamily=Arial Narrow','fontFamily=Times New Roman').replace('strokeColor=#333333','strokeColor='+STROKE))
    ET.SubElement(c,'mxGeometry',x=str(x),y=str(y),width=str(x1-x),height=str(y1-y),attrib={'as':'geometry'})
def edge(id,source,target,pts):
    c=ET.SubElement(root,'mxCell',id=id,source=source,target=target,edge='1',parent='1',style='endArrow=none;startArrow=none;strokeColor=#333333;strokeWidth=1;')
    if SAMPLE:
        c.set('style',c.get('style').replace('strokeColor=#333333','strokeColor='+STROKE)+'fontFamily=Times New Roman;fontSize=22;labelBackgroundColor=#ffffff;')
        if target in relation_ids:
            f=next(f for f in fks if f['id']==target)
            c.set('value',f['parent_range'] if id[3]=='p' else f['child_range'])
    g=ET.SubElement(c,'mxGeometry',relative='1',attrib={'as':'geometry'});arr=ET.SubElement(g,'Array',attrib={'as':'points'})
    for x,y in pts[1:-1]:ET.SubElement(arr,'mxPoint',x=str(x),y=str(y))
for r in routed:
    for i,delta in enumerate((-1.6,1.6) if r['double'] else (0,)):
        points=offset(r['pts'],delta) if delta else r['pts'];line(points)
        edge(r['id']+'_'+str(i),r['source'],r['target'],points)
for a in attrs:
    cx,cy=centers[a['entity']];line([(cx,cy),(a['x'],a['y'])]);edge(a['id']+'_attr',a['entity'],a['id'],[(cx,cy),(a['x'],a['y'])])
for a in attrs:
    x,y=a['x'],a['y'];box=shapes[a['id']]
    fill='#fff2cc' if SAMPLE and a['pk'] else '#ffffff'
    stroke='#d6b656' if SAMPLE and a['pk'] else STROKE
    draw.ellipse(box,fill=fill,outline=stroke,width=1)
    svg.append(f'<ellipse cx="{x}" cy="{y}" rx="{AW/2}" ry="{AH/2}" fill="{fill}" stroke="{stroke}" stroke-width="1"/>')
    # Arial Narrow preserves complete SQL names at about 6.5 pt when placed 18 cm wide.
    ts=23
    while font(ts,SAMPLE and a['pk']).getlength(a['col'])>AW-20:ts-=1
    assert ts>=22,(a['col'],ts)
    a['fontSize']=ts
    text(x,y,a['col'],ts,center=True,pk=a['pk'],bold=SAMPLE and a['pk'])
    vertex(a['id'],('<b><u>'+a['col']+'</u></b>' if SAMPLE else '<u>'+a['col']+'</u>') if a['pk'] else a['col'],'ellipse',fill)
    if SAMPLE and a['pk']:root[-1].set('style',root[-1].get('style').replace('strokeColor='+STROKE,'strokeColor=#d6b656'))
for name,(cx,cy) in centers.items():
    fill='#ffffff' if SAMPLE else '#e6e6e6'
    box=shapes[name];draw.rectangle(box,fill=fill,outline=STROKE,width=1)
    svg.append(f'<rect x="{box[0]}" y="{box[1]}" width="{EW}" height="{EH}" fill="{fill}" stroke="{STROKE}"/>')
    label=re.sub(r'(?<!^)(?=[A-Z])','_',name).upper()
    strings=['STUDENT_CLASS','ASSIGNMENT'] if name=='StudentClassAssignment' else [label]
    if SAMPLE:strings=['StudentClass','Assignment'] if name=='StudentClassAssignment' else [name]
    for i,s in enumerate(strings):text(cx,cy+(i-(len(strings)-1)/2)*22,s,23,center=True,bold=True)
    vertex(name,'<b>'+'<br/>'.join(strings)+'</b>','rectangle',fill)
for f in fks:
    x,y=f['x'],f['y'];poly=[(x-RW,y),(x,y-RH),(x+RW,y),(x,y+RH)]
    fill='#ffffff' if SAMPLE else '#eeeeee'
    draw.polygon(poly,fill=fill,outline=STROKE)
    svg.append('<polygon points="'+' '.join(f'{a},{b}' for a,b in poly)+f'" fill="{fill}" stroke="{STROKE}"/>')
    words=f['label'].split();strings=[f['label']]
    if len(f['label'])>11:
        at=min(range(1,len(words)),key=lambda j:abs(len(' '.join(words[:j]))-len(' '.join(words[j:]))));strings=[' '.join(words[:at]),' '.join(words[at:])]
    for i,s in enumerate(strings):text(x,y+(i-(len(strings)-1)/2)*21,s,21,center=True)
    # White label boxes prevent line crossings from obscuring cardinality numerals.
    cards=[(x-RW-8,y-23,f['parent_range']),(x+RW+8,y+23,f['child_range'])] if SAMPLE else [(x-RW-15,y,'1'),(x+RW+15,y,f['max'])]
    for xx,yy,label in cards:
        half=font(22).getlength(label)/2+3
        draw.rectangle((xx-half,yy-14,xx+half,yy+14),fill='white');svg.append(f'<rect x="{xx-half}" y="{yy-14}" width="{2*half}" height="28" fill="white"/>');text(xx,yy,label,22,center=True)
    vertex(f['id'],'<br/>'.join(strings),'rhombus',fill)
    if not SAMPLE:root[-1].set('style',root[-1].get('style').replace('fontFamily=Arial Narrow','fontFamily=Arial'))
text(900,33,'ERD CHEN DBMS12',34,center=True,bold=True)
text(900,72,'12 thực thể · 99 thuộc tính · 19 quan hệ',24,center=True)
text(55,2470,'Elip vàng và gạch chân: khóa chính.' if SAMPLE else 'Gạch chân: khóa chính. 1/N: lực lượng tối đa.',23)
text(55,2505,'1: đúng một; 0..1: tối đa một; 0..N: không hoặc nhiều.' if SAMPLE else 'Đường đôi: tham gia bắt buộc; đường đơn: tùy chọn.',23)
text(55,2540,'Giữ nguyên tên thuộc tính và các quan hệ theo schema DBMS12.' if SAMPLE else 'Tên thuộc tính giữ nguyên theo schema. Không có thực thể yếu.',23)
svg.append('</svg>')
(OUT/(BASE+'.svg')).write_text('\n'.join(svg),encoding='utf-8')
im.save(OUT/(BASE+'.png'),dpi=(254,254))
# Exact A4 portrait media box, with the 180 x 260 mm diagram inside 15 mm margins.
page=Image.new('RGB',(2100,2970),'white');page.paste(im,(150,150))
page.save(OUT/(BASE+'.pdf'),resolution=254)
ET.indent(mx);ET.ElementTree(mx).write(OUT/(BASE+'.drawio'),encoding='utf-8',xml_declaration=True)
md=['# ERD Chen cho một trang A4 dọc','','Dàn lại thành2cột×6hàng; giữ đủ12thực thể,99thuộc tính,19quan hệ và phong cách giáo trình. Không thu nhỏ ảnh ngang cũ.','',
    '![ERD A4 dọc](ERD-Chen-A4-portrait.png)','','[SVG vector](ERD-Chen-A4-portrait.svg) · [PNG](ERD-Chen-A4-portrait.png) · [PDF một trang A4](ERD-Chen-A4-portrait.pdf) · [drawio](ERD-Chen-A4-portrait.drawio)','','## Chèn vào Word','',
    '1. Layout → Size → A4; Orientation → Portrait.',
    '2. Margins → Custom Margins: đặt cả bốn lề1,5cm.',
    '3. Insert → Pictures → chọnSVG (ưu tiên) hoặcPNG. Đặt In Line with Text, khóa tỷ lệ, Width=18cm; Height≈26cm.',
    '4. Đặt đoạn chứa ảnh Before=0, After=0, line spacing Single. Không chèn thêm caption dài trên cùng trang; ảnh đã có tiêu đề.',
    '', 'SVG có kích thước vật lý18×26cm;PDF210×297mm đúng một trang. PNG1800×2600px,254dpi. Chữ thuộc tính23đơn vị tương đương6,52pt khi in rộng18cm, lớn hơn đáng kể bản ngang cũ (~1,36pt cùng chiều rộng). Vì giữ đủ99thuộc tính và19quan hệ, chữ vẫn nhỏ; phải xem/in đúng100% để đánh giá. Không claim dễ đọc như nội dung thân bài11–12pt.',
    '', 'Đường nối được dàn lại tránh các hộp chứa chữ; vẫn có giao cắt giữa đường trong mô hình nhiều quan hệ. KiểuSQL/NULL/UNIQUE chi tiết xemERD-full-attributes.md. Không bỏ thuộc tính hoặc thay model để ép trang.','']
if SAMPLE:
    md=['# ERD Chen A4 theo mẫu báo cáo','','Sơ đồ sử dụng phong cách ảnh mẫu: thực thể và quan hệ có nền trắng, viền xám mảnh, font Times New Roman; tên thực thể in đậm; khóa chính nằm trong elip vàng nhạt và được gạch chân. Tên bảng và thuộc tính giữ nguyên theo SQL của dự án.','',
        '![ERD theo mẫu](ERD-Chen-A4-sample.png)','','[SVG](ERD-Chen-A4-sample.svg) · [PNG](ERD-Chen-A4-sample.png) · [PDF một trang A4](ERD-Chen-A4-sample.pdf) · [drawio](ERD-Chen-A4-sample.drawio)','','## Nội dung và lực lượng','',
        'Sơ đồ có đủ 12 thực thể, 99 thuộc tính và 19 quan hệ. Các đường nối dùng nét đơn với nhãn min..max như ảnh mẫu. Nhãn phía cha cho biết số cha của mỗi con: 1 hoặc 0..1 theo khả năng NULL của FK. Nhãn phía con cho biết số con của mỗi cha: 0..1 nếu FK là UNIQUE, 0..N nếu không. Nhãn đặt cạnh hình thoi, lệch trên/dưới để tránh chồng chữ trong trang A4.','',
        'DDL không buộc mỗi bản ghi cha phải có ít nhất một bản ghi con. Course có thể chưa có lớp; Registration chưa duyệt chưa có Invoice; Class chưa xếp lớp chưa có assignment. Vì vậy các quan hệ này dùng 0..N hoặc 0..1. Quy trình ứng dụng còn có điều kiện theo trạng thái.','',
        'Class.current_grade_operation_id tham chiếu AuditLog.operation_id (UK). AuditLog.root_entity_id là tham chiếu theo action, không phải FK vật lý. StudentClassAssignment có tối đa một GradeReport theo DDL; ứng dụng tạo report stub cùng giao dịch xếp lớp.','',
        '## Chèn Word A4 dọc','',
        'Chọn A4 Portrait, đặt cả bốn lề 1,5 cm. Chèn SVG (ưu tiên) hoặc PNG, chọn In Line with Text, giữ tỷ lệ và đặt rộng 18 cm, cao 26 cm. Đặt khoảng cách đoạn Before/After bằng 0. Ảnh đã có tiêu đề; tránh thêm chú thích dài làm tràn trang.','',
        'SVG có kích thước 18 × 26 cm; PNG 1800 × 2600 px, 254 dpi; PDF đúng một trang 210 × 297 mm. Chữ thuộc tính Times New Roman tương đương 6,24–6,52 pt khi ảnh rộng 18 cm, vẫn nhỏ vì giữ đủ 99 thuộc tính. Thay đổi này chỉ thuộc cách trình bày, không thay đổi schema, dữ liệu hoặc runtime.','']
(OUT/(BASE+'.md')).write_text('\n'.join(md),encoding='utf-8')
ET.parse(OUT/(BASE+'.svg'));doc=ET.parse(OUT/(BASE+'.drawio'))
assert len(doc.findall('.//mxCell[@vertex="1"]'))==130 and len(doc.findall('.//mxCell[@edge="1"]'))==(137 if SAMPLE else 152)
pdf=(OUT/(BASE+'.pdf')).read_bytes();assert len(re.findall(rb'/Type /Page\b',pdf))==1
receipt={'date':'2026-10-22','entities':12,'attributes':99,'relationships':19,'layout':'2 columns 6 rows','diagramMm':[180,260],'pageMm':[210,297],'pdfPages':1,'fontPtAt18cm':23/10/25.4*72,'recommendedWordMarginsCm':1.5,'recommendedWordWidthCm':18,'routedLegs':len(routed),'schemaSha256':hashlib.sha256(DDL.read_bytes()).hexdigest().upper(),
         'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest().upper() for p in sorted(OUT.glob(BASE+'.*'))}}
if SAMPLE:receipt.update(style='White shapes, pale gold primary keys, Times New Roman, explicit min/max',primaryKeyHighlights=12,edgeCount=137,attributeFontPtRange=[min(a['fontSize'] for a in attrs)/10/25.4*72,max(a['fontSize'] for a in attrs)/10/25.4*72])
(ROOT/('docs/evidence/erd-chen-a4-sample.json' if SAMPLE else 'docs/evidence/erd-chen-a4.json')).write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in receipt.items() if k!='files'}))
