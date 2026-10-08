import React, { useState } from 'react';
import { SUGGESTED_TAGS, normalizeTagList } from '../lib/tags';

type TagPickerProps = {
  value: string[];
  onChange: (tags: string[]) => void;
  label?: string;
};

export function TagPicker({ value, onChange, label = '标签' }: TagPickerProps) {
  const [draft, setDraft] = useState('');
  const tags = normalizeTagList(value);

  const toggle = (tag: string) => {
    if (tags.includes(tag)) {
      onChange(tags.filter((t) => t !== tag));
    } else {
      onChange(normalizeTagList([...tags, tag]));
    }
  };

  const addCustom = () => {
    const t = draft.trim();
    if (!t) return;
    onChange(normalizeTagList([...tags, t]));
    setDraft('');
  };

  return (
    <div className="loan-tag-picker">
      <div className="loan-label">{label}</div>
      <div className="loan-tag-grid" role="group" aria-label={label}>
        {SUGGESTED_TAGS.map((tag) => (
          <button
            key={tag}
            type="button"
            className="loan-tag-chip"
            data-active={tags.includes(tag)}
            onClick={() => toggle(tag)}
          >
            {tag}
          </button>
        ))}
      </div>
      <div className="loan-tag-custom">
        <input
          className="loan-input"
          placeholder="自定义标签，回车添加"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              addCustom();
            }
          }}
        />
        <button type="button" className="loan-btn-secondary loan-tag-add-btn" onClick={addCustom}>
          添加
        </button>
      </div>
      {tags.length > 0 ? (
        <div className="loan-tag-selected">
          {tags.map((t) => (
            <span key={t} className="loan-tag-pill">
              {t}
              <button
                type="button"
                aria-label={`移除 ${t}`}
                onClick={() => onChange(tags.filter((x) => x !== t))}
              >
                ×
              </button>
            </span>
          ))}
        </div>
      ) : (
        <p className="loan-muted" style={{ fontSize: 12, margin: '8px 0 0' }}>
          至少选一个标签，便于筛选
        </p>
      )}
    </div>
  );
}

export function TagRow({ tags }: { tags: string[] }) {
  if (!tags.length) return null;
  return (
    <div className="loan-tag-row">
      {tags.map((t) => (
        <span key={t} className="loan-tag-pill loan-tag-pill--readonly">
          {t}
        </span>
      ))}
    </div>
  );
}
