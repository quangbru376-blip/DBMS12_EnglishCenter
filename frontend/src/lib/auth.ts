export type AuthContext = Readonly<{
 accountId:number;fullName:string;email:string;
 role:'Student'|'Admissions'|'AcademicAffairs'|'Teacher'|'Accountant'|'Director'|'Admin';
 scope:'NORMAL'|'PASSWORD_CHANGE';accountVersion:string;serverTime:string;
 absoluteExpiresAt:string;effectiveExpiresAt:string;
}>;
