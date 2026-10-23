import { useEffect, useId, useRef } from 'react';
import type { ReactNode } from 'react';
import { Button } from './Button';

type ModalProps = {
  open: boolean;
  title: string;
  children: ReactNode;
  onRequestClose: () => void;
  className?: string;
  closeDisabled?: boolean;
};

export function Modal({ open, title, children, onRequestClose, className = '', closeDisabled = false }: ModalProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const headingId = useId();

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!open || !dialog) return;
    const opener = document.activeElement;
    dialog.showModal();
    return () => {
      dialog.close();
      if (opener instanceof HTMLElement && opener.isConnected) opener.focus();
    };
  }, [open]);

  useEffect(() => {
    if (open && closeDisabled) dialogRef.current?.focus();
  }, [open, closeDisabled]);

  const requestClose = () => { if (!closeDisabled) onRequestClose(); };

  return (
    <dialog
      ref={dialogRef}
      aria-labelledby={headingId}
      tabIndex={-1}
      className={`ec-modal ${className}`}
      onCancel={(event) => { if (event.target !== event.currentTarget) return; event.preventDefault(); event.stopPropagation(); requestClose(); }}
      onKeyDown={(event) => {
        if (event.key !== 'Tab' || (event.target instanceof Element && event.target.closest('dialog') !== event.currentTarget)) return;
        event.stopPropagation();
        const items = Array.from(event.currentTarget.querySelectorAll<HTMLElement>(
          'button:not(:disabled), input:not(:disabled), select:not(:disabled), textarea:not(:disabled), a[href], [tabindex="0"]',
        )).filter((item) => item.getClientRects().length > 0);
        if (!items.length) { event.preventDefault(); event.currentTarget.focus(); return; }
        const first = items[0];
        const last = items.at(-1);
        if (event.shiftKey && document.activeElement === first && last) {
          event.preventDefault(); last.focus();
        } else if (!event.shiftKey && document.activeElement === last && first) {
          event.preventDefault(); first.focus();
        }
      }}
      onClick={(event) => {
        if (event.target !== event.currentTarget) return;
        const rect = event.currentTarget.getBoundingClientRect();
        if (event.clientX < rect.left || event.clientX > rect.right ||
            event.clientY < rect.top || event.clientY > rect.bottom) requestClose();
      }}
    >
      <div className="ec-modal-header">
        <h2 id={headingId} className="text-lg font-semibold">{title}</h2>
        <Button variant="secondary" disabled={closeDisabled} onClick={requestClose} aria-label="Đóng hộp thoại">Đóng</Button>
      </div>
      <div className="ec-modal-body">{children}</div>
    </dialog>
  );
}
