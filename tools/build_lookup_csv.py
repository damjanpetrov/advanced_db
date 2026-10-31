"""Генерира lookup CSV-ата во 01_data/csv/ (имиња, презимиња, градови, улици по група/држава).
Извор: рачни листи (македонски, албански) + листите од библиотеката Faker за другите држави.
Се пушта еднаш: python3 tools/build_lookup_csv.py  (бара: pip install faker unidecode)"""
import csv, random, re, importlib
from unidecode import unidecode
from faker import Faker
random.seed(42)
OUT='01_data/csv/'
def lat(s): return re.sub(r'[^a-z0-9]', '', unidecode(s).lower())

# ---------- Македонски (рачно + Faker mk_MK) ----------
mk_m = """Александар Никола Стефан Марко Давид Филип Петар Димитар Јован Андреј Матеј Лука Михаил Владимир Горан Дејан Зоран Игор Бојан Дарко Кристијан Мартин Виктор Иван Благој Ристе Трајче Ѓорѓи Мирко Сашо Тони Христијан Кирил Васил Душко Илија Огнен Борис Даниел Ангел Павле Тодор Методиј Наум Климент Славе Стојан Трајан Јордан Здравко Златко Љупчо Мите Митко Аце Пеце Кире Боге Бранко Владо Влатко Гоце Гордан Горјан Даме Драган Ѓоко Ѓорге Емил Живко Зафир Звонко Ивица Игнат Илче Јане Јанко Јосиф Константин Коце Крсте Ламбе Лазар Љубе Љубомир Марјан Милан Миле Милош Мирослав Наце Ненад Новица Орце Пане Перо Петре Раде Ранко Ратко Сашко Симе Симон Славчо Слободан Стевче Страхил Тасе Томе Томислав Тоше Трпе Христо Цане Цветан Алексеј Антон Арсен Атанас Борче Видое Дамјан Кочо Венко Велко Бранислав Јулијан Теодор Леон Габриел Алекс Ноа Јакоб""".split()
mk_f = """Ана Марија Елена Ивана Сара Мила Јована Теодора Катерина Симона Александра Билјана Весна Снежана Даниела Маја Ема Анастасија Мартина Николина Христина Драгана Светлана Лидија Ирена Наташа Габриела Ангела Кристина Тамара Бојана Моника Виолета Верица Емилија Јасмина Благица Валентина Вера Гордана Дафина Дијана Душица Евгенија Елизабета Жаклина Загорка Зорица Ивона Илина Ирина Искра Јагода Јана Јелена Јулијана Калина Каролина Кети Лена Лилјана Љубица Љупка Магдалена Марина Марта Маргарита Мери Милена Мирјана Михаела Нада Надица Невена Нина Олгица Оливера Павлина Петра Радица Рената Сандра Сашка Силвана Слаѓана Соња Софија Стефанија Стојанка Сузана Татјана Теона Фросина Цветанка Ангелина Андреа Ања Бранка Вања Викторија Даница Деспина Драгица Ева Ива Јадранка Јордана Лара Леа Матеа Неда Нора Ружица Сања Тијана Хана Хелена""".split()
fk = importlib.import_module('faker.providers.person.mk_MK').Provider
mk_m = sorted(set(mk_m) | set(fk.first_names_male)); mk_f = sorted(set(mk_f) | set(fk.first_names_female))

# Презимиња: основа (-ов/-ев) → 3 реални варијанти: Петров, Петровски, Петроски (+ женски форми)
bases = """Петров Николов Стојанов Трајков Јованов Илиев Димитров Ристов Атанасов Стефанов Андонов Најдов Костов Митрев Наумов Спасов Тасев Велков Ангелов Георгиев Јакимов Марков Кузманов Павлов Симонов Здравков Богданов Тодоров Цветков Костадинов Арсов Блажев Ѓорѓиев Анчев Мицев Ефремов Киров Талев Стојчев Јанкулов Стојков Иванов Попов Димов Танев Велев Јанев Митев Кочев Стоименов Ѓоргиев Пешев Гоцев Алексов Апостолов Бојаџиев Василев Велјанов Гаврилов Глигоров Грозданов Дамјанов Донев Зафиров Јовчев Климов Коцев Крстев Лазаров Манев Милев Мирчев Мишев Наков Нешков Пандов Панов Пејчев Пенев Петрушев Петковски Пецев Попев Радев Ралев Саздов Секулов Силјанов Славев Србинов Стамков Стаматов Стерјов Таков Тасков Темелков Трендафилов Тупанчев Филипов Христов Цветанов Чавдаров Шопов Јорданов Јосифов Јанакиев Зендров Ковачев Терзиев Кујунџиев Абаџиев Ќурчиев Мајсторов Калајџиев Пекаров Касапов Бакалов Ковачов Дуганов Кантаров Ќосев Ѓурчинов Бабунов Бошков Бранков Велинов Веселинов Вешов Витанов Влахов Гаџов Гегов Генов Гетов Гичев Глишев Горгиев Горјанов Грков Гулев Давков Дачев Дебарлиев Делев Дељов Деспотов Дојчинов Донков Дуков Ѓеоргиев Ѓуров Жежов Живков Зајков Зарев Звездов Здравев Зинов Златанов Злаков Иличков Ичев Јаков Јанчев Јовев Јолев Јончев Јошев Каевски Калев Камчев Каранфилов Карев Кацарски Кимов Китанов Кирков Кичев Клинчаров Колев Колишев Конев Котев Кралев Кузев Кукушев Кумбаров Лалев Лафчиев Лешков Лимов Лозанов Луков Љапчев Мадев Мајсторов Малинов Мангов Маринов Мартинов Матеев Мачков Мендов Мечкаров Миладинов Милчев Минов Мирков Митков Михајлов Мојсов Мукаетов Мучев Најденов Нанев Начев Неделков Ненов Нетков Нинов Новачев Ортаков Ошавков Павков Палчев Пауновски Пашов Пенков Перчинков Пешков Пипонов Поцков Пренџов Прчков Пуљков Ракиџиев Ралпов Ренџов Ризов Ристевски Рогачев Ромев Руменов Сајков Сандев Сарафов Светиев Седларов Серафимов Симјанов Синадинов Сирков Ситнов Смилев Соколов Сотиров Спировски Срезов Станков Стевков Стерјев Стојменов Сукаров Тајков Танчев Тапанчев Теов Тетовски Тодев Тосев Тошев Трајанов Трипунов Тричков Трпков Тунев Ќирков Узунов Урдов Фидановски Филев Фотев Хаџиев Хаџи-Митков Хинков Христовски Цанев Цацев Цонев Цуцулов Чамовски Чапаров Чочев Чулев Шалев Шапков Шекеринов Шијаков Шкартов Шопов Штерјов Шулев""".split()
def variants(b):
    out=set()
    if b.endswith('ски'):
        out.add((b, b[:-1]+'а'))
        return out
    if not (b.endswith('ов') or b.endswith('ев')): return out
    out.add((b, b+'а')); out.add((b+'ски', b+'ска'))
    w = b[:-2] + ('оски' if b.endswith('ов') else 'ески')
    out.add((w, w[:-1]+'а'))
    return out
mk_sur=set()
for b in bases: mk_sur |= variants(b)
for s in fk.last_names_male:
    f = s[:-1]+'а' if s.endswith('ски') else (s+'а' if s.endswith(('ов','ев')) else s)
    mk_sur.add((s,f))
mk_sur=sorted(mk_sur)

# ---------- Албански (рачно; се користи за Албанци во МК и за Албанија) ----------
al_m="Arben Besnik Ardit Florian Driton Bujar Agon Valon Arian Albion Blerim Bekim Gzim Dardan Enver Fatmir Fisnik Hamdi Ilir Kenan Lirim Muhamed Naser Orhan Petrit Ramadan Rexhep Sami Shpetim Tahir Vedat Visar Xhelal Jeton Labinot Mendim Mirlind Nuredin Urim Esat Arton Besart Dren Erion Fation Gent Hekuran Klodian Leotrim Mergim Nderim Qendrim Rinor Shkelzen Taulant Uran Vigan Xhevdet Ylber Zgjim Adem Bajram Burim Endrit Ermal Gëzim Ismet Kujtim".split()
al_f="Arjeta Blerta Drita Arbnora Vjosa Fatime Aida Albulena Almira Ariana Besa Blerina Donjeta Erblina Flutura Gentiana Iliriana Jehona Kaltrina Lirie Mimoza Rozafa Teuta Adriana Enkelejda Ardiana Elira Luljeta Medina Merita Ajshe Emine Fatma Melek Sibel Afërdita Anila Besjana Doruntina Edona Fjolla Hana Ilirjana Jeta Kaltrina Liridona Majlinda Njomza Qëndresa Rina Shqipe Valbona Vlora Yllka Zana Zamira".split()
al_sur="Ahmeti Jashari Ismaili Sulejmani Ramadani Memeti Zendeli Shabani Ibraimi Aliu Rushiti Ademi Bajrami Kasami Selimi Bexheti Xhaferi Murati Iseni Mustafa Hasani Rexhepi Imeri Saliu Osmani Asani Idrizi Jakupi Rustemi Sadiku Veliu Fetahu Abdullahu Beqiri Berisha Bytyqi Dauti Demiri Elezi Emini Fazliu Gashi Haliti Hoxha Hyseni Islami Jahiu Kadriu Kryeziu Krasniqi Limani Maliqi Mehmeti Morina Musliu Nuhiu Pajaziti Qerimi Rama Rexha Sejdiu Shala Shehu Sopi Tahiri Thaqi Useini Vrapi Xhemaili Ymeri Zeqiri Zeka Avdiu Bislimi Dalipi Emurli Fejzulai".split()
al_m, al_f, al_sur = sorted(set(al_m)), sorted(set(al_f)), sorted(set(al_sur))

rows_fn=[]; rows_sn=[]
for n in mk_m: rows_fn.append(('MK','M',n,lat(n)))
for n in mk_f: rows_fn.append(('MK','F',n,lat(n)))
for m,f in mk_sur: rows_sn.append(('MK','M',m,lat(m))); rows_sn.append(('MK','F',f,lat(f)))
for grp in ('MKA','AL'):
    for n in al_m: rows_fn.append((grp,'M',n,lat(n)))
    for n in al_f: rows_fn.append((grp,'F',n,lat(n)))
    for s in al_sur: rows_sn.append((grp,'A',s,lat(s)))

# ---------- Други држави од Faker ----------
faker_groups = {'BG':'bg_BG','GR':'el_GR','HR':'hr_HR','SI':'sl_SI','RO':'ro_RO','TR':'tr_TR','DE':'de_DE',
                'AT':'de_AT','IT':'it_IT','NL':'nl_NL','ES':'es_ES','PL':'pl_PL','US':'en_US'}
def as_list(v): return list(v.keys()) if isinstance(v, dict) else list(v)
for grp, loc in faker_groups.items():
    P = importlib.import_module('faker.providers.person.'+loc).Provider
    for g, attr in (('M','first_names_male'),('F','first_names_female')):
        for n in sorted(set(as_list(getattr(P, attr)))):
            if lat(n): rows_fn.append((grp,g,n,lat(n)))
    lm = getattr(P,'last_names_male',None); lf = getattr(P,'last_names_female',None)
    if lm and lf:
        for s in sorted(set(as_list(lm))): rows_sn.append((grp,'M',s,lat(s)))
        for s in sorted(set(as_list(lf))): rows_sn.append((grp,'F',s,lat(s)))
    else:
        for s in sorted(set(as_list(P.last_names))): rows_sn.append((grp,'A',s,lat(s)))
# Полски презимиња: Faker има само генератор → земаме примерок
pl = Faker('pl_PL'); pl.seed_instance(1)
pls=set()
while len(pls) < 600: pls.add(pl.last_name())
rows_sn=[r for r in rows_sn if r[0]!='PL'] + [('PL','A',s,lat(s)) for s in sorted(pls)]
rows_fn=[r for r in rows_fn if r[3]]; rows_sn=[r for r in rows_sn if r[3]]
# презимиња што во Faker почнуваат со мала буква (пр. „volk“) → голема почетна буква
rows_sn=[(g,ge,(s[0].upper()+s[1:]) if s[0].islower() and ' ' not in s else s,l) for g,ge,s,l in rows_sn]
# дупликати по (група, пол, име)
rows_fn=sorted(set(rows_fn)); rows_sn=sorted(set(rows_sn))

with open(OUT+'first_names.csv','w',newline='',encoding='utf-8') as f:
    w=csv.writer(f); w.writerow(['grp','gender','name','name_lat']); w.writerows(rows_fn)
with open(OUT+'surnames.csv','w',newline='',encoding='utf-8') as f:
    w=csv.writer(f); w.writerow(['grp','gender','surname','surname_lat']); w.writerows(rows_sn)

# ---------- Градови и улици по држава ----------
mk_cities=[('Скопје',520),('Куманово',100),('Битола',75),('Тетово',70),('Прилеп',66),('Охрид',52),('Гостивар',50),('Велес',48),('Струмица',45),('Штип',44),('Струга',37),('Кавадарци',30),('Кочани',28),('Кичево',27),('Радовиш',24),('Гевгелија',22),('Дебар',15),('Крива Паланка',14),('Свети Николе',13),('Неготино',13),('Делчево',11),('Виница',10),('Ресен',9),('Пробиштип',9),('Берово',7),('Кратово',7),('Валандово',7)]
mk_streets = sorted(set("""Партизанска;Илинденска;Македонија;Гоце Делчев;Јане Сандански;Даме Груев;11 Октомври;8 Септември;Борис Трајковски;Кочо Рацин;Мирче Ацев;Никола Карев;Питу Гули;Цар Самоил;Климент Охридски;Свети Кирил и Методиј;Христијан Тодоровски Карпош;Васил Главинов;Орце Николов;Скупи;Народни Херои;Димитрија Чуповски;Петар Поп Арсов;Ѓорче Петров;Браќа Миладиновци;Јордан Мијалков;Наум Наумовски Борче;Христо Татарчев;Беласица;Пелистер;Шар Планина;Вардарска;Прешевска;Охридска;Битолска;Кумановска;Тетовска;Струшка;Јадранска""".split(';')) | set(importlib.import_module('faker.providers.address.mk_MK').Provider.streets))
manual = {
 'AL': (['Tiranë','Durrës','Vlorë','Elbasan','Shkodër','Fier','Korçë','Berat','Lushnjë','Kavajë','Gjirokastër','Sarandë'],
        ['Rruga e Durrësit','Rruga Myslym Shyri','Bulevardi Zogu I','Rruga e Kavajës','Rruga Ibrahim Rugova','Rruga Sami Frashëri','Rruga Pjetër Bogdani','Rruga Naim Frashëri','Rruga Skënderbeu','Rruga Hoxha Tahsim','Rruga Gjergj Fishta','Rruga e Elbasanit','Rruga Ismail Qemali','Rruga Luigj Gurakuqi','Rruga 28 Nëntori','Rruga Asim Vokshi','Rruga Mine Peza','Rruga Qemal Stafa','Rruga Bajram Curri','Rruga Fan Noli']),
 'BG': (['София','Пловдив','Варна','Бургас','Русе','Стара Загора','Плевен','Сливен','Добрич','Шумен','Благоевград','Кюстендил','Петрич','Перник','Хасково'],
        ['бул. Витоша','бул. Христо Ботев','ул. Граф Игнатиев','бул. Васил Левски','ул. Раковски','бул. Цар Освободител','ул. Шипка','ул. Славянска','бул. България','ул. Иван Вазов','ул. Алеко Константинов','ул. Гео Милев','ул. Цар Симеон','бул. Мария Луиза','ул. Опълченска','ул. Пиротска','бул. Сливница','ул. Хан Аспарух','ул. Стефан Караджа','ул. Оборище']),
 'TR': (['İstanbul','Ankara','İzmir','Bursa','Antalya','Edirne','Eskişehir','Konya','Kocaeli','Tekirdağ'],
        ['Atatürk Caddesi','Cumhuriyet Caddesi','İstiklal Caddesi','Gazi Bulvarı','İnönü Caddesi','Fevzi Çakmak Sokak','Mimar Sinan Caddesi','Barbaros Bulvarı','Bağdat Caddesi','Ziya Gökalp Sokak','Necatibey Caddesi','Hürriyet Caddesi','Mevlana Caddesi','Kazım Karabekir Caddesi','Millet Caddesi','Fatih Sokak','Yıldız Sokak','Lale Sokak','Gül Sokak','Çınar Sokak']),
}
faker_addr = {'GR':'el_GR','HR':'hr_HR','SI':'sl_SI','RO':'ro_RO','DE':'de_DE','AT':'de_AT','IT':'it_IT','NL':'nl_NL','ES':'es_ES','PL':'pl_PL','US':'en_US'}
cities=[('MK',c,w) for c,w in mk_cities]; streets=[('MK',s) for s in mk_streets]
for g,(cs,ss) in manual.items():
    cities += [(g,c,max(1,12-i)) for i,c in enumerate(cs)]; streets += [(g,s) for s in ss]
for g,loc in faker_addr.items():
    fk2=Faker(loc); fk2.seed_instance(7)
    cs=[]; seen=set()
    while len(cs) < 25:
        c=fk2.city()
        if c not in seen: seen.add(c); cs.append(c)
    cities += [(g,c,max(1,26-i)) for i,c in enumerate(cs)]
    ss=set(); tries=0
    while len(ss) < 150 and tries < 5000:
        ss.add(fk2.street_name()); tries+=1
    streets += [(g,s) for s in sorted(ss)]
with open(OUT+'cities.csv','w',newline='',encoding='utf-8') as f:
    w=csv.writer(f); w.writerow(['grp','city','weight']); w.writerows(cities)
with open(OUT+'streets.csv','w',newline='',encoding='utf-8') as f:
    w=csv.writer(f); w.writerow(['grp','street']); w.writerows(streets)

# капацитет на уникатни комбинации по група
from collections import Counter, defaultdict
fn=defaultdict(int); sn=defaultdict(int)
for g,ge,_,_ in rows_fn: fn[(g,ge)]+=1
for g,ge,_,_ in rows_sn: sn[(g,ge)]+=1
for g in sorted({r[0] for r in rows_fn}):
    cap = sum(fn[(g,ge)]*(sn[(g,ge)]+sn[(g,'A')]) for ge in 'MF')
    print(g, 'names', fn[(g,'M')], fn[(g,'F')], 'surnames', sn[(g,'M')], sn[(g,'F')], sn[(g,'A')], 'combos', cap)
print('cities', len(cities), 'streets', len(streets))
