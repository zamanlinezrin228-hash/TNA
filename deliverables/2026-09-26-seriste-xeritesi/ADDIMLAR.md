# Səriştə Xəritəsi + şöbə üzrə TNA + şöbə rəhbəri Dashboard — tətbiq addımları

Heç nə avtomatik tətbiq edilməyib: nə Supabase-də, nə də GitHub-da (`telim-tracker-v2`) dəyişiklik yoxdur.
Aşağıdakı addımları özünüz, bu ardıcıllıqla edin.

---

## Addım 1 — SQL (Supabase → SQL Editor)

1. `sql/2026-09-26_competency_catalog.sql` faylını açın, **bütöv** məzmununu SQL Editor-a yapışdırın və **Run** edin.
   - Yalnız **yeni** cədvəllər yaradır: `competency_areas` (13), `competency_catalog` (830), `competency_role_map` (684),
     `competency_area_rules` (51) + `resolve_competency_area()` funksiyası.
   - Mövcud `competency_library` cədvəlinə **toxunmur** (köhnə TNA sətirləri IDP-də tanınmağa davam etsin deyə).
   - Təkrar işlətmək təhlükəsizdir (yeni cədvəlləri silib yenidən yaradır).
   - Sonunda yoxlama: `select count(*) from competency_catalog;` → **830** olmalıdır.
2. (İstəyə bağlı, yalnız oxuma) `sql/2026-09-26_competency_coverage_check_readonly.sql` — hər real departament/şöbə
   üçün hansı sahənin seçildiyini göstərir. `YOXLA` yazılan sətirlər: sahə tapılmayıb → TNA-da "bütün sahələr" göstərilir.
   Belə şöbə varsa, mənə adını yazın, qayda əlavə edim (və ya `competency_area_rules`-a özünüz əlavə edin).

> Vacib: SQL-i kodu yükləmədən **əvvəl** işlədin. Əks halda yeni səhifə "Səriştə kataloqu yüklənmədi" yazacaq.

## Addım 2 — Kod faylları (`telim-tracker-v2` reposu)

İki yoldan biri:

**A) Faylları əvəz edin** — `files/` qovluğundakı hər faylı repoda eyni yola kopyalayın:

| Fayl | Nə dəyişib |
|---|---|
| `components/CompetencyMapView.jsx` | **YENİ** — "Səriştə Xəritəsi" səhifəsi |
| `lib/competency.js` | **YENİ** — kataloqun yüklənməsi, şöbə → sahə qaydası |
| `components/AnnualTnaForm.jsx` | TNA: səriştələr şöbəyə görə (vəzifədən asılı deyil), sətir üzrə "Sahə" seçimi |
| `components/DashboardView.jsx` | Şöbə rəhbərinin boş Dashboard xətası düzəldildi |
| `pages/index.js` | Yeni səhifə marşrutu + Dashboard-a düzgün məlumat ötürülməsi |
| `components/Sidebar.jsx` | Menyuya "Səriştə Xəritəsi" |
| `components/HomeScreen.jsx` | Əsas səhifəyə "Səriştə Xəritəsi" kartı |
| `components/IdpView.jsx` | IDP həm köhnə, həm yeni kataloqdakı səriştələri tanıyır |
| `styles/globals.css` | Yeni səhifənin dizaynı (faylın sonuna əlavə olunub) |
| `sql/2026-09-26_*.sql` | Arxiv üçün `sql/` qovluğuna da qoya bilərsiniz |

**B) Patch** — repo kökündə: `git apply deyisiklikler.patch` (hazırkı `main` üzərində yoxlanılıb, təmiz tətbiq olunur).
SQL faylları patch-də yoxdur — onları `sql/` qovluğuna ayrıca kopyalayın.

Sonra: `npm run build` → commit → `main`-ə push (Vercel avtomatik deploy edəcək).

## Addım 3 — Yoxlama (deploydan sonra)

- **Səriştə Xəritəsi** (menyuda): Departament/sahə + Vəzifə seçin → PDP üslubunda profil (kritiklik, tələb olunan səviyyə).
  "Bütün vəzifələr" → sahənin tam kataloqu; "Matris" → vəzifələr × səriştələr (analiz üçün). Hər kəs görür, yalnız baxış üçündür.
- **İllik TNA**: ERP şöbəsindən (Biznes tətbiqləri və avtomatlaşdırma şöbəsi) bir əməkdaş seçin → "Sahə: ERP / İT və Rəqəmsal
  (avtomatik)" və 70 ERP səriştəsi çıxmalıdır, **Maliyyə yox**. Mühasibatlıq şöbəsindən biri → Maliyyə (73).
- **Dashboard**: şöbə rəhbəri ilə daxil olun → rəqəmlər artıq boş olmamalıdır (İzləmə Cədvəlindəki eyni əməkdaşlar).

---

## Məntiq — necə uyğunlaşdırılır

1. Əvvəl **şöbə** yoxlanılır, sonra **departament**. Məs.: ERP şöbəsi Maliyyə departamentinin içindədir, amma şöbə qaydası
   ("biznes tətbiqləri" → ERP) birinci işləyir, ona görə ERP əməkdaşları maliyyə səriştələri yox, İT/ERP səriştələri görür.
   Eyni qayda: Data analitika şöbəsi → Biznes Analitikası.
2. TNA-da sahənin **bütün** səriştələri göstərilir, vəzifəyə görə süzülmür. Vəzifə səviyyəsində baxış — Səriştə Xəritəsi səhifəsindədir.
3. Qaydanı dəyişmək üçün kod lazım deyil — `competency_area_rules` cədvəlinə sətir əlavə edin
   (`match_on` = 'sube' və ya 'dept', `pattern` = adın bir hissəsi, `area` = FIN/ERP/BA/SAL/MKT/LOG/SCM/HRM/RSK/LEG/ADM/HSE/SEC,
   kiçik `priority` = daha əvvəl yoxlanılır).
4. Sahəsi tapılmayan bölmələr (məs. "İdarəetmə") üçün TNA-da bütün 13 sahə göstərilir; istifadəçi hər sətirdə sahəni əl ilə dəyişə bilər.

## Yoxlamanız lazım olan qərarlar

- **Biznesin inkişafı şöbəsi → Satış** kimi qəbul edildi (kitabxanada ayrıca sahə yoxdur). Başqa sahə olmalıdırsa, deyin.
- **Kataloq Azərbaycan dilindədir** (əvvəl göndərdiyiniz AZ kitabxana — yeni EN kitabxananın sətir-sətir tərcüməsidir, 830 kodun
  hamısı 1:1 uyğun gəlir). İngiliscə orijinal da saxlanılır — səhifədə "İngiliscə orijinalı göstər" ilə görünür.
- Dashboard düzəlişinin səbəbi: 2026 təlim importunda şöbə sütunu yoxdur (bütün sətirlərdə `sube` boşdur), Dashboard isə şöbə
  rəhbərini təlim sətirinin öz `sube` sahəsi ilə süzürdü → 0 nəticə. İndi İzləmə Cədvəli ilə eyni üsul (profil → əməkdaş adı) istifadə olunur.
