import { useCallback, useEffect, useRef, useState } from 'react';
import type { Dbms12Client, Payload, Row } from './api';

export type ListQuery = { path:string; params:Payload; id:string };
type State = { key:string; rows:Row[]; total:number|null; hasMore:boolean; loading:boolean; error:string };
export type ScrollList = State & { ready:boolean; loadMore:()=>void };
const empty:State={key:'',rows:[],total:null,hasMore:false,loading:false,error:''};

// One query generation owns its pages; late responses cannot enter a newer list.
export function useScrollList(client:Dbms12Client,query:ListQuery|null,key:string):ScrollList {
  const [state,setState]=useState<State>(empty);
  const loader=useRef<()=>void>(()=>{});
  const loadMore=useCallback(()=>loader.current(),[]);
  useEffect(()=>{
    if(!query){loader.current=()=>{};return;}
    let active=true,pending=false,page=1,hasMore=true;
    let rows:Row[]=[],total:number|null=null;
    const load=async()=>{
      if(!active||pending||!hasMore)return;
      pending=true;
      setState({key,rows,total,hasMore,loading:true,error:''});
      try{
        const result=await client.read(query.path,{...query.params,page,pageSize:20});
        if(!active)return;
        const batch=result.filter(r=>query.id in r);
        const reported=result.find(r=>'total' in r)?.total;
        if(reported!==undefined&&Number.isSafeInteger(Number(reported))&&Number(reported)>=0)total=Number(reported);
        const seen=new Set(rows.map(r=>String(r[query.id])));
        rows=[...rows,...batch.filter(r=>{const id=String(r[query.id]);if(seen.has(id))return false;seen.add(id);return true;})];
        hasMore=batch.length>0&&(total===null?batch.length===20:rows.length<total);
        page++;
        setState({key,rows,total,hasMore,loading:false,error:''});
      }catch(e){if(active)setState({key,rows,total,hasMore,loading:false,error:e instanceof Error?e.message:'Không thể tải danh sách.'});}
      finally{pending=false;}
    };
    loader.current=()=>{void load();};
    const timer=setTimeout(()=>{void load();},0);
    return()=>{active=false;clearTimeout(timer);loader.current=()=>{};};
  },[client,query,key]);
  const current=state.key===key?state:empty;
  return {...current,ready:!query||state.key===key,loading:!!query&&(state.key!==key||current.loading),loadMore};
}
