-- YALNIZ OXUMA (heç nəyi dəyişmir). 2026-09-26_competency_catalog.sql-dan SONRA işlədin.
-- Hər real departament/şöbə cütü üçün hansı səriştə sahəsinin seçildiyini və
-- neçə səriştə görünəcəyini göstərir. "YOXLA" olan sətirlər üçün ya
-- competency_area_rules-a qayda əlavə edin, ya da elə saxlayın (o halda TNA-da
-- "bütün sahələr" göstərilir və istifadəçi sahəni özü seçir).

select
  p.dept,
  p.sube,
  count(*)                                             as emekdas_sayi,
  public.resolve_competency_area(p.dept, p.sube)       as sahe,
  a.label                                              as sahe_adi,
  (select count(*) from public.competency_catalog c
    where c.area = public.resolve_competency_area(p.dept, p.sube)) as seriste_sayi,
  case when public.resolve_competency_area(p.dept, p.sube) is null
       then 'YOXLA — sahə tapılmadı (bütün sahələr göstəriləcək)' end as qeyd
from public.profiles p
left join public.competency_areas a on a.key = public.resolve_competency_area(p.dept, p.sube)
group by p.dept, p.sube, a.label
order by (public.resolve_competency_area(p.dept, p.sube) is null) desc, p.dept, p.sube;

-- Sahə üzrə yekun: hər sahədə neçə səriştə, neçə PDP vəzifəsi var.
select a.key, a.label,
       (select count(*) from public.competency_catalog c where c.area = a.key)                  as seriste_sayi,
       (select count(distinct m.position) from public.competency_role_map m where m.area = a.key) as pdp_vezife_sayi
from public.competency_areas a
order by a.sort_order;
