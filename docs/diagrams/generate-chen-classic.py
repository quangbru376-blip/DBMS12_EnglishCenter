"""Apply the owner's textbook Chen style to the editable, DDL-derived diagram."""
from pathlib import Path
import math, re, html, json, hashlib
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
DDL=ROOT/'database/dbms12-compact/01_schema.sql';sql=DDL.read_text(encoding='utf-8-sig')
tables={}
for name,body in re.findall(r'CREATE TABLE dbo\.\[(\w+)\] \((.*?)\n\);',sql,re.S):
    cols=[m.groups() for s in body.splitlines() if (m:=re.match(r'\s*\[(\w+)\]\s+(\w+(?:\([\d,]+\))?).*?\b(NOT NULL|NULL)\b',s))]
    tables[name]={'cols':cols,'pk':re.findall(r'\[(\w+)\]',re.search(r'PRIMARY KEY \((.*?)\)',body)[1]),'uq':[re.findall(r'\[(\w+)\]',s) for s in re.findall(r'\bUNIQUE \((.*?)\)',body)]}
fks=[dict(child=c,col=f,parent=p,target=t,id=f'R{i+1:02}') for i,(c,f,p,t) in enumerate(re.findall(r'ALTER TABLE dbo\.\[(\w+)\].*?FOREIGN KEY \(\[(\w+)\]\) REFERENCES dbo\.\[(\w+)\] \(\[(\w+)\]\)',sql))]
assert len(tables)==12 and sum(len(t['cols']) for t in tables.values())==99 and len(fks)==19
source=ET.parse(OUT/'ERD-Chen.drawio');cells={c.get('id'):c for c in source.findall('.//mxCell')}
sx,sy,tx,ty=1.25,1.2,180,160
W,H=9360,5520
def scale(p):return (p[0]*sx+tx,p[1]*sy+ty)
def geometry(c):
    g=c.find('mxGeometry');return tuple(float(g.get(k)) for k in ('x','y','width','height'))
def center(c):
    x,y,w,h=geometry(c);return scale((x+w/2,y+h/2))
centers={n:center(cells[n]) for n in tables}
font=lambda size,b=False:ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf' if b else 'C:/Windows/Fonts/arial.ttf',size)
im=Image.new('RGB',(W,H),'white');draw=ImageDraw.Draw(im)
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="100%" height="100%" fill="white"/>']
mx=ET.Element('mxfile',host='app.diagrams.net');dg=ET.SubElement(mx,'diagram',name='Chen classic - textbook style')
gm=ET.SubElement(dg,'mxGraphModel',page='1',pageWidth=str(W),pageHeight=str(H));root=ET.SubElement(gm,'root');ET.SubElement(root,'mxCell',id='0');ET.SubElement(root,'mxCell',id='1',parent='0')
def text(x,y,s,size=27,centered=False,underline=False,bold=False):
    f=font(size,bold);width=draw.textlength(s,font=f)
    if centered:x-=width/2
    draw.text((x,y),s,font=f,fill='#111111')
    if underline:draw.line((x,y+size+2,x+width,y+size+2),fill='#111111',width=2)
    svg.append(f'<text x="{x}" y="{y+size}" font-family="Arial,sans-serif" font-size="{size}" fill="#111111"'+(' text-decoration="underline"' if underline else '')+(' font-weight="700"' if bold else '')+'>'+html.escape(s)+'</text>')
def lines_text(x,y,strings,size=27):
    for i,s in enumerate(strings):text(x,y+(i-(len(strings)-1)/2)*(size+4)-size/2,s,size,centered=True)
def line(pts,width=2):
    draw.line(pts,fill='#333333',width=width)
    svg.append('<polyline points="'+' '.join(f'{x},{y}' for x,y in pts)+f'" fill="none" stroke="#333333" stroke-width="{width}"/>')
def offset(pts,amount):
    # Parallel offsets with averaged normals at bends; joins remain readable at print scale.
    result=[]
    for i,(x,y) in enumerate(pts):
        normals=[]
        if i:
            dx,dy=x-pts[i-1][0],y-pts[i-1][1];l=math.hypot(dx,dy)
            if l:normals.append((-dy/l,dx/l))
        if i<len(pts)-1:
            dx,dy=pts[i+1][0]-x,pts[i+1][1]-y;l=math.hypot(dx,dy)
            if l:normals.append((-dy/l,dx/l))
        nx=sum(p[0] for p in normals);ny=sum(p[1] for p in normals);l=math.hypot(nx,ny) or 1
        result.append((x+amount*nx/l,y+amount*ny/l))
    return result
def vertex(id,value,x,y,w,h,shape,fill):
    c=ET.SubElement(root,'mxCell',id=id,value=value,vertex='1',parent='1',style=f'shape={shape};html=1;whiteSpace=wrap;fillColor={fill};strokeColor=#333333;strokeWidth=2;fontColor=#111111;fontFamily=Arial;fontSize=28;')
    ET.SubElement(c,'mxGeometry',x=str(x-w/2),y=str(y-h/2),width=str(w),height=str(h),attrib={'as':'geometry'})
def edge(id,source,target,pts,double=False):
    for k,shift in enumerate((-5,5) if double else (0,)):
        pp=offset(pts,shift) if shift else pts
        line(pp)
        c=ET.SubElement(root,'mxCell',id=id+('_'+str(k) if double else ''),source=source,target=target,edge='1',parent='1',style='endArrow=none;startArrow=none;strokeColor=#333333;strokeWidth=2;html=1;')
        g=ET.SubElement(c,'mxGeometry',relative='1',attrib={'as':'geometry'})
        arr=ET.SubElement(g,'Array',attrib={'as':'points'})
        for x,y in pp[1:-1]:ET.SubElement(arr,'mxPoint',x=str(x),y=str(y))
        # Separate attachment points for the parallel pair on the editable output.
        if double:
            sc=cells.get(source);tc=cells.get(target)
            for key,cc,p in [('exit',sc,pp[0]),('entry',tc,pp[-1])]:
                if cc is not None:
                    x,y,w,h=geometry(cc);x,y=scale((x,y));w*=sx;h*=sy
                    c.set('style',c.get('style')+f'{key}X={(p[0]-x)/w};{key}Y={(p[1]-y)/h};{key}Perimeter=1;')

text(150,45,'DBMS12 — ERD CHEN',52,bold=True)
text(150,115,'12 thực thể  ·  99 thuộc tính  ·  19 quan hệ',30)
mandatory=0
relation_data=[]
for f in fks:
    rc=cells[f['id']];rx,ry=center(rc);x,y,w,h=geometry(rc);rw=w*sx/2;rh=h*sy/2
    label=re.sub('<[^>]+>',' ',rc.get('value')).split(f['id'])[0].strip().upper()
    f['label']=label;f['mid']=(rx,ry);f['rw']=rw;f['rh']=rh
    nullable=next(c[2]=='NULL' for c in tables[f['child']]['cols'] if c[0]==f['col'])
    unique=[f['col']] in tables[f['child']]['uq'] or f['col']=='current_grade_operation_id'
    f['mandatory']=not nullable;f['max']='1' if unique else 'N';mandatory+=int(not nullable)
    for suffix,start,end,total in [('p',f['parent'],f['id'],False),('c',f['id'],f['child'],not nullable)]:
        original=cells[f['id']+suffix]
        pp=[center(cells[start])]+[scale((float(p.get('x')),float(p.get('y')))) for p in original.findall('.//mxPoint')]+[center(cells[end])]
        edge(f['id']+suffix,start,end,pp,double=total)
        # Traditional Chen maximum-cardinality labels (optional/mandatory uses single/double lines).
        entity=f['parent'] if suffix=='p' else f['child'];cx,cy=centers[entity]
        near=pp[1] if suffix=='p' else pp[-2]
        sign=-1 if near[1]<cy else 1
        text(cx+22,cy+sign*155-17,'1' if suffix=='p' else f['max'],29)
    relation_data.append(f)

attribute_count=0
for name,t in tables.items():
    cx,cy=centers[name];n=len(t['cols']);half=(n+1)//2
    radius_x,radius_y=(920,430) if n>12 else (680,360)
    attrs=[]
    for i,(col,typ,null) in enumerate(t['cols']):
        side=-1 if i<half else 1;j=i if side==-1 else i-half;count=half if side==-1 else n-half
        theta=math.radians(-55+110*j/(count-1)) if count>1 else 0
        ax=cx+side*radius_x*math.cos(theta);ay=cy+radius_y*math.sin(theta)
        # Spokes connect the entity to each ellipse; ellipse interiors mask the endpoint.
        edge(name+'_'+col+'_link',name,name+'_'+col,[(cx,cy),(ax,ay)])
        attrs.append((col,typ,null,ax,ay))
    for col,typ,null,ax,ay in attrs:
        pk=col in t['pk'];ew,eh=400,68
        draw.ellipse((ax-ew/2,ay-eh/2,ax+ew/2,ay+eh/2),fill='white',outline='#333333',width=2)
        svg.append(f'<ellipse cx="{ax}" cy="{ay}" rx="{ew/2}" ry="{eh/2}" fill="white" stroke="#333333" stroke-width="2"/>')
        text(ax,ay-18,col,25,centered=True,underline=pk)
        vertex(name+'_'+col,('<u>'+col+'</u>') if pk else col,ax,ay,ew,eh,'ellipse','#ffffff')
        attribute_count+=1
    ew,eh=600,132
    draw.rectangle((cx-ew/2,cy-eh/2,cx+ew/2,cy+eh/2),fill='#e6e6e6',outline='#333333',width=2)
    svg.append(f'<rect x="{cx-ew/2}" y="{cy-eh/2}" width="{ew}" height="{eh}" fill="#e6e6e6" stroke="#333333" stroke-width="2"/>')
    entity_label=re.sub(r'(?<!^)(?=[A-Z])','_',name).upper()
    ls=['STUDENT_CLASS','ASSIGNMENT'] if name=='StudentClassAssignment' else [entity_label]
    lines_text(cx,cy,ls,30)
    vertex(name,'<br/>'.join(ls),cx,cy,ew,eh,'rectangle','#e6e6e6')

# Draw diamonds last so no unrelated crossing is visible through a relationship label.
for f in relation_data:
    x,y=f['mid'];rw,rh=f['rw'],f['rh']
    poly=[(x-rw,y),(x,y-rh),(x+rw,y),(x,y+rh)]
    draw.polygon(poly,fill='#eeeeee',outline='#333333',width=2)
    svg.append('<polygon points="'+' '.join(f'{a},{b}' for a,b in poly)+'" fill="#eeeeee" stroke="#333333" stroke-width="2"/>')
    words=f['label'].split();ls=[f['label']]
    if len(f['label'])>15:
        at=min(range(1,len(words)),key=lambda j:abs(len(' '.join(words[:j]))-len(' '.join(words[j:]))));ls=[' '.join(words[:at]),' '.join(words[at:])]
    lines_text(x,y,ls,28)
    vertex(f['id'],'<br/>'.join(ls),x,y,2*rw,2*rh,'rhombus','#eeeeee')

text(150,H-225,'Hình chữ nhật: thực thể. Hình thoi: quan hệ. Elip: thuộc tính. Gạch chân: khóa chính.',30)
text(150,H-165,'1 / N: lực lượng tối đa. Đường đơn: tham gia tùy chọn. Đường đôi: tham gia bắt buộc ở phía có khóa ngoại NOT NULL.',29)
text(150,H-105,'Không có thực thể yếu hoặc khóa bộ phận trong model này. NULL, UNIQUE và FK chi tiết xem tài liệu kèm theo.',29)
svg.append('</svg>')
BASE='ERD-Chen-classic'
(OUT/(BASE+'.svg')).write_text('\n'.join(svg),encoding='utf-8');im.save(OUT/(BASE+'.png'))
ET.indent(mx);ET.ElementTree(mx).write(OUT/(BASE+'.drawio'),encoding='utf-8',xml_declaration=True)
# Single entity enlargement pages retain radial spokes and all attributes.
pages=[im]
for name,(cx,cy) in centers.items():
    page=Image.new('RGB',(2420,1320),'white');pd=ImageDraw.Draw(page)
    crop=im.crop((cx-1140,cy-600,cx+1140,cy+600));page.paste(crop,(70,65))
    pd.rectangle((0,0,2420,70),fill='white');pd.text((55,20),name.upper()+' — ATTRIBUTES',font=font(34),fill='#111111')
    pages.append(page)
pages[0].save(OUT/(BASE+'.pdf'),save_all=True,append_images=pages[1:],resolution=180)
md=['# ERD Chen — phong cách giáo trình','','Áp dụng phong cách ảnh mẫu owner gửi ngày22/10/2026. Đây là biểu diễn của đúng model12 hiện có, không đổi thiết kế database.','',
    '![ERD Chen cổ điển](ERD-Chen-classic.png)','','[SVG](ERD-Chen-classic.svg) · [PDF13trang](ERD-Chen-classic.pdf) · [diagrams.net chỉnh sửa](ERD-Chen-classic.drawio)','','## Phân tích phong cách mẫu','',
    '- Nền trắng, nét đen mảnh, không dùng màu phân nhóm hoặc đổ bóng.',
    '- Thực thể là hình chữ nhật xám nhạt; quan hệ là hình thoi xám nhạt; tên viết hoa.',
    '- Thuộc tính elip trắng, nối tỏa bằng các đoạn thẳng; khóa chính gạch chân liền.',
    '- Nhãn1/N mô tả lực lượng tối đa; đường đôi thể hiện tham gia toàn phần, đường đơn là tùy chọn.',
    '- Ảnh mẫu có khung đôi/thoi đôi/khóa gạch chân đứt cho thực thể yếu và quan hệ định danh. Model này mỗi bảng cóPK riêng, không có khóa bộ phận: không sao chép các ký hiệu đó sai ngữ nghĩa.',
    '', '## Áp dụng vào project', '',
    'Giữ12thực thể,99thuộc tính,19quan hệ. Không gắn dấu? trong elip để gần phong cách giáo trình; NULL và kiểu SQL có ở ERD-full-attributes.md. Không chuyển thuộc tính kỹ thuật hayFK thành thuộc tính của quan hệ chỉ để bắt chước dữ liệu hàng không.',
    '', f'Có{mandatory}quan hệ với FK NOT NULL: phía con nối đôi đến hình thoi. Bốn FK nullable (R06,R11,R16,R17) giữ đường đơn. Phía cha đều tùy chọn vì FK không bắt mỗi bản ghi cha phải có con; ứng dụng có thể thêm invariant mạnh hơn trong giao dịch. Nhãn1/N không thể hiện min: kết hợp đường đơn/đôi mới thể hiện optional/mandatory.',
    '', 'Không suy thực thể yếu chỉ vì FK NOT NULL. MộtAuthSession phụ thuộcAccount để tồn tại vẫn cósid làmPK độc lập; dùng tham gia toàn phần và khung đơn.',
    '', '## Quan hệ đối chiếu DDL', '', '|Mã|Quan hệ|Cha|Con|Nguồn FK|Tỷ lệ tối đa|Phía con|','|---|---|---|---|---|---|---|']
for f in fks:md.append(f'|{f["id"]}|{f["label"]}|{f["parent"]}|{f["child"]}|{f["col"]} → {f["target"]}|1:{f["max"]}|'+('Bắt buộc, đường đôi' if f['mandatory'] else 'Tùy chọn, đường đơn')+'|')
md += ['', 'Class.current_grade_operation_id tham chiếuAuditLog.operation_id(UK), có filteredUNIQUE. AuditLog.root_entity_id không phảiFK vật lý. KiểuSQL/nullability/UNIQUE ghép và các guard khác theoDDL, không thêm nét nối giả.','']
(OUT/(BASE+'.md')).write_text('\n'.join(md),encoding='utf-8')
ET.parse(OUT/(BASE+'.svg'));doc=ET.parse(OUT/(BASE+'.drawio'))
assert attribute_count==99 and mandatory==15
assert len(doc.findall('.//mxCell[@vertex="1"]'))==130 and len(doc.findall('.//mxCell[@edge="1"]'))==152
assert len(re.findall(rb'/Type /Page\b',(OUT/(BASE+'.pdf')).read_bytes()))==13
receipt={'date':'2026-10-22','style':'Textbook monochrome Chen with radial attributes','entities':12,'attributes':99,'relationships':19,'primaryKeysUnderlined':12,'mandatoryChildParticipations':15,'optionalChildParticipations':4,'weakEntities':0,'pdfPages':13,'drawioVertices':130,'drawioEdges':152,
         'schemaSha256':hashlib.sha256(DDL.read_bytes()).hexdigest().upper(),
         'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest().upper() for p in sorted(OUT.glob(BASE+'.*'))}}
(ROOT/'docs/evidence/erd-chen-classic.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in receipt.items() if k!='files'}))
