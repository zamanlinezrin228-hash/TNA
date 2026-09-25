-- ============================================================================
-- CSV variantı üçün SXEM (məlumat yoxdur). Səriştə Kataloqu cədvəllərini,
-- oxuma icazələrini və şöbə -> sahə funksiyasını yaradır.
--
-- Ardıcıllıq:
--   1) Bu faylı SQL Editor-da işlədin (boş cədvəllər yaranır).
--   2) Table Editor -> hər cədvəl -> Insert -> "Import data from CSV",
--      MÜTLƏQ bu sırada (xarici açarlara görə):
--        1_competency_areas.csv      -> competency_areas       (13 sətir)
--        2_competency_catalog.csv    -> competency_catalog     (830 sətir)
--        3_competency_role_map.csv   -> competency_role_map    (684 sətir)
--        4_competency_area_rules.csv -> competency_area_rules  (50 sətir)
--
-- 2026-09-26_competency_catalog.sql (tam SQL variantı) ilə EYNİ nəticəni
-- verir — ikisindən birini seçin, ikisini birlikdə yox. id-lər CSV-də hazır
-- verilir (vəzifə xəritəsi kataloqa id ilə bağlanır), ona görə id sütunları
-- avtomatik artan deyil.
--
-- Mövcud competency_library cədvəlinə TOXUNMUR. Təkrar işlətsəniz yeni
-- cədvəllər silinib boş yaradılır — CSV-ləri yenidən yükləməli olacaqsınız.
-- ============================================================================

begin;

drop function if exists public.resolve_competency_area(text, text);
drop function if exists public.competency_norm(text);
drop table if exists public.competency_role_map;
drop table if exists public.competency_area_rules;
drop table if exists public.competency_catalog;
drop table if exists public.competency_areas;

create table public.competency_areas (
  key text primary key,
  label text not null,
  label_en text,
  sort_order int not null default 0
);

create table public.competency_catalog (
  id bigint primary key,
  area text not null references public.competency_areas(key) on delete cascade,
  sort_order int not null,
  code text,
  category text,
  competency text,
  sub_competency text not null,
  category_en text,
  competency_en text,
  sub_competency_en text,
  unique (area, sort_order)
);
create index competency_catalog_area_idx on public.competency_catalog(area);

create table public.competency_role_map (
  id bigint primary key,
  area text not null references public.competency_areas(key) on delete cascade,
  dept_label text not null,
  position text not null,
  catalog_id bigint not null references public.competency_catalog(id) on delete cascade,
  criticality smallint check (criticality between 1 and 5),
  required_level smallint check (required_level between 1 and 5),
  unique (area, position, catalog_id)
);
create index competency_role_map_area_pos_idx on public.competency_role_map(area, position);

create table public.competency_area_rules (
  id bigint primary key,
  match_on text not null check (match_on in ('sube', 'dept')),
  pattern text not null,
  area text references public.competency_areas(key) on delete cascade,
  priority int not null default 100,
  note text
);

-- Oxuma hamı üçün (daxil olmuş istifadəçilər), yazma yalnız SQL Editor-dan.
alter table public.competency_areas enable row level security;
alter table public.competency_catalog enable row level security;
alter table public.competency_role_map enable row level security;
alter table public.competency_area_rules enable row level security;
create policy "Səriştə sahələrini hamı oxuya bilər" on public.competency_areas for select to authenticated using (true);
create policy "Səriştə kataloqunu hamı oxuya bilər" on public.competency_catalog for select to authenticated using (true);
create policy "Vəzifə xəritəsini hamı oxuya bilər" on public.competency_role_map for select to authenticated using (true);
create policy "Sahə qaydalarını hamı oxuya bilər" on public.competency_area_rules for select to authenticated using (true);

-- Azərbaycan hərfləri üçün etibarlı kiçik hərf + İ/I/ı birləşdirmə (JS-dəki
-- lib/competency.js normText() ilə eyni qayda).
create function public.competency_norm(s text) returns text
language sql immutable as $$
  select regexp_replace(lower(translate(coalesce(s, ''), 'İIıƏŞÇÖÜĞ', 'iiiəşçöüğ')), '\s+', ' ', 'g')
$$;

-- Əvvəl şöbə qaydaları, sonra departament qaydaları (priority artan sırada).
create function public.resolve_competency_area(p_dept text, p_sube text) returns text
language sql stable as $$
  select r.area from public.competency_area_rules r
  where (r.match_on = 'sube' and public.competency_norm(p_sube) <> ''
         and public.competency_norm(p_sube) like '%' || public.competency_norm(r.pattern) || '%')
     or (r.match_on = 'dept' and public.competency_norm(p_dept) <> ''
         and public.competency_norm(p_dept) like '%' || public.competency_norm(r.pattern) || '%')
  order by case r.match_on when 'sube' then 0 else 1 end, r.priority
  limit 1
$$;
grant execute on function public.resolve_competency_area(text, text) to authenticated;

commit;
