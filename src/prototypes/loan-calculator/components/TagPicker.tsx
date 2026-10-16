import React, { useState } from 'react';
import { useApp } from '../context';
import { SUGGESTED_TAGS, normalizeTagList, tagLabel } from '../lib/tags';

type TagPickerProps = {
  value: string[];
  onChange: (tags: string[]) => void;
  label?: string;
};

export function TagPicker({ value, onChange, label }: TagPickerProps) {
  const { t } = useApp();
  const [draft, setDraft] = useState('');
  const tags = normalizeTagList(value);
  const fieldLabel = label ?? t('tag.label');

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
      <div className="loan-label">{fieldLabel}</div>
      <div className="loan-tag-grid" role="group" aria-label={fieldLabel}>
        {SUGGESTED_TAGS.map((tag) => (
          <button
            key={tag}
            type="button"
            className="loan-tag-chip"
            data-active={tags.includes(tag)}
            onClick={() => toggle(tag)}
          >
            {tagLabel(tag, t)}
          </button>
        ))}
      </div>
      <div className="loan-tag-custom">
        <input
          className="loan-input"
          placeholder={t('tag.custom')}
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
          {t('tag.add')}
        </button>
      </div>
      {tags.length > 0 ? (
        <div className="loan-tag-selected">
          {tags.map((tag) => (
            <span key={tag} className="loan-tag-pill">
              {tagLabel(tag, t)}
              <button
                type="button"
                aria-label={t('tag.remove', { name: tagLabel(tag, t) })}
                onClick={() => onChange(tags.filter((x) => x !== tag))}
              >
                ×
              </button>
            </span>
          ))}
        </div>
      ) : (
        <p className="loan-muted" style={{ fontSize: 12, margin: '8px 0 0' }}>
          {t('tag.needOne')}
        </p>
      )}
    </div>
  );
}

export function TagRow({ tags }: { tags: string[] }) {
  const { t } = useApp();
  if (!tags.length) return null;
  return (
    <div className="loan-tag-row">
      {tags.map((tag) => (
        <span key={tag} className="loan-tag-pill loan-tag-pill--readonly">
          {tagLabel(tag, t)}
        </span>
      ))}
    </div>
  );
}
