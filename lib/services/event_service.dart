import 'dart:math' as math;
import '../data/el_paso_events.dart';
import '../data/event_dedupe.dart';
import '../models/event.dart';
import '../repositories/event_repository.dart';
import 'ticketmaster_service.dart';

// ── Zip prefix → US state abbreviation ────────────────────────────────────────
// Covers all 50 states. First 3 digits of a 5-digit zip map to a state code.
const Map<String, String> _zipPrefixToState = {
  // Alabama
  '350':'AL','351':'AL','352':'AL','354':'AL','355':'AL','356':'AL','357':'AL',
  '358':'AL','359':'AL','360':'AL','361':'AL','362':'AL','363':'AL','364':'AL',
  '365':'AL','366':'AL','367':'AL','368':'AL','369':'AL',
  // Alaska
  '995':'AK','996':'AK','997':'AK','998':'AK','999':'AK',
  // Arizona
  '850':'AZ','851':'AZ','852':'AZ','853':'AZ','855':'AZ','856':'AZ','857':'AZ',
  '859':'AZ','860':'AZ','863':'AZ','864':'AZ','865':'AZ',
  // Arkansas
  '716':'AR','717':'AR','718':'AR','719':'AR','720':'AR','721':'AR','722':'AR',
  '723':'AR','724':'AR','725':'AR','726':'AR','727':'AR','728':'AR','729':'AR',
  // California
  '900':'CA','901':'CA','902':'CA','903':'CA','904':'CA','905':'CA','906':'CA',
  '907':'CA','908':'CA','910':'CA','911':'CA','912':'CA','913':'CA','914':'CA',
  '915':'CA','916':'CA','917':'CA','918':'CA','919':'CA','920':'CA','921':'CA',
  '922':'CA','923':'CA','924':'CA','925':'CA','926':'CA','927':'CA','928':'CA',
  '930':'CA','931':'CA','932':'CA','933':'CA','934':'CA','935':'CA','936':'CA',
  '937':'CA','938':'CA','939':'CA','940':'CA','941':'CA','942':'CA','943':'CA',
  '944':'CA','945':'CA','946':'CA','947':'CA','948':'CA','949':'CA','950':'CA',
  '951':'CA','952':'CA','953':'CA','954':'CA','955':'CA','956':'CA','957':'CA',
  '958':'CA','959':'CA','960':'CA','961':'CA',
  // Colorado
  '800':'CO','801':'CO','802':'CO','803':'CO','804':'CO','805':'CO','806':'CO',
  '807':'CO','808':'CO','809':'CO','810':'CO','811':'CO','812':'CO','813':'CO',
  '814':'CO','815':'CO','816':'CO',
  // Connecticut
  '060':'CT','061':'CT','062':'CT','063':'CT','064':'CT','065':'CT','066':'CT',
  '067':'CT','068':'CT','069':'CT',
  // Delaware
  '197':'DE','198':'DE','199':'DE',
  // Florida
  '320':'FL','321':'FL','322':'FL','323':'FL','324':'FL','325':'FL','326':'FL',
  '327':'FL','328':'FL','329':'FL','330':'FL','331':'FL','332':'FL','333':'FL',
  '334':'FL','335':'FL','336':'FL','337':'FL','338':'FL','339':'FL','341':'FL',
  '342':'FL','344':'FL','346':'FL','347':'FL','349':'FL',
  // Georgia
  '300':'GA','301':'GA','302':'GA','303':'GA','304':'GA','305':'GA','306':'GA',
  '307':'GA','308':'GA','309':'GA','310':'GA','311':'GA','312':'GA','313':'GA',
  '314':'GA','315':'GA','316':'GA','317':'GA','318':'GA','319':'GA',
  // Hawaii
  '967':'HI','968':'HI',
  // Idaho
  '832':'ID','833':'ID','834':'ID','835':'ID','836':'ID','837':'ID','838':'ID',
  // Illinois
  '600':'IL','601':'IL','602':'IL','603':'IL','604':'IL','605':'IL','606':'IL',
  '607':'IL','608':'IL','609':'IL','610':'IL','611':'IL','612':'IL','613':'IL',
  '614':'IL','615':'IL','616':'IL','617':'IL','618':'IL','619':'IL','620':'IL',
  '621':'IL','622':'IL','623':'IL','624':'IL','625':'IL','626':'IL','627':'IL',
  '628':'IL','629':'IL',
  // Indiana
  '460':'IN','461':'IN','462':'IN','463':'IN','464':'IN','465':'IN','466':'IN',
  '467':'IN','468':'IN','469':'IN','470':'IN','471':'IN','472':'IN','473':'IN',
  '474':'IN','475':'IN','476':'IN','477':'IN','478':'IN','479':'IN',
  // Iowa
  '500':'IA','501':'IA','502':'IA','503':'IA','504':'IA','505':'IA','506':'IA',
  '507':'IA','508':'IA','510':'IA','511':'IA','512':'IA','513':'IA','514':'IA',
  '515':'IA','516':'IA','520':'IA','521':'IA','522':'IA','523':'IA','524':'IA',
  '525':'IA','526':'IA','527':'IA','528':'IA',
  // Kansas
  '660':'KS','661':'KS','662':'KS','664':'KS','665':'KS','666':'KS','667':'KS',
  '668':'KS','669':'KS','670':'KS','671':'KS','672':'KS','673':'KS','674':'KS',
  '675':'KS','676':'KS','677':'KS','678':'KS','679':'KS',
  // Kentucky
  '400':'KY','401':'KY','402':'KY','403':'KY','404':'KY','405':'KY','406':'KY',
  '407':'KY','408':'KY','409':'KY','410':'KY','411':'KY','412':'KY','413':'KY',
  '414':'KY','415':'KY','416':'KY','417':'KY','418':'KY',
  // Louisiana
  '700':'LA','701':'LA','703':'LA','704':'LA','705':'LA','706':'LA','707':'LA',
  '708':'LA','710':'LA','711':'LA','712':'LA','713':'LA','714':'LA',
  // Maine
  '039':'ME','040':'ME','041':'ME','042':'ME','043':'ME','044':'ME','045':'ME',
  '046':'ME','047':'ME','048':'ME','049':'ME',
  // Maryland
  '206':'MD','207':'MD','208':'MD','209':'MD','210':'MD','211':'MD','212':'MD',
  '214':'MD','215':'MD','216':'MD','217':'MD','218':'MD','219':'MD',
  // Massachusetts
  '010':'MA','011':'MA','012':'MA','013':'MA','014':'MA','015':'MA','016':'MA',
  '017':'MA','018':'MA','019':'MA','020':'MA','021':'MA','022':'MA','023':'MA',
  '024':'MA','025':'MA','026':'MA','027':'MA',
  // Michigan
  '480':'MI','481':'MI','482':'MI','483':'MI','484':'MI','485':'MI','486':'MI',
  '487':'MI','488':'MI','489':'MI','490':'MI','491':'MI','492':'MI','493':'MI',
  '494':'MI','495':'MI','496':'MI','497':'MI','498':'MI','499':'MI',
  // Minnesota
  '550':'MN','551':'MN','553':'MN','554':'MN','555':'MN','556':'MN','557':'MN',
  '558':'MN','559':'MN','560':'MN','561':'MN','562':'MN','563':'MN','564':'MN',
  '565':'MN','566':'MN','567':'MN',
  // Mississippi
  '386':'MS','387':'MS','388':'MS','389':'MS','390':'MS','391':'MS','392':'MS',
  '393':'MS','394':'MS','395':'MS','396':'MS','397':'MS',
  // Missouri
  '630':'MO','631':'MO','633':'MO','634':'MO','635':'MO','636':'MO','637':'MO',
  '638':'MO','639':'MO','640':'MO','641':'MO','644':'MO','645':'MO','646':'MO',
  '647':'MO','648':'MO','649':'MO','650':'MO','651':'MO','652':'MO','653':'MO',
  '654':'MO','655':'MO','656':'MO','657':'MO','658':'MO',
  // Montana
  '590':'MT','591':'MT','592':'MT','593':'MT','594':'MT','595':'MT','596':'MT',
  '597':'MT','598':'MT','599':'MT',
  // Nebraska
  '680':'NE','681':'NE','683':'NE','684':'NE','685':'NE','686':'NE','687':'NE',
  '688':'NE','689':'NE','690':'NE','691':'NE','692':'NE','693':'NE',
  // Nevada
  '889':'NV','890':'NV','891':'NV','893':'NV','894':'NV','895':'NV','897':'NV',
  '898':'NV',
  // New Hampshire
  '030':'NH','031':'NH','032':'NH','033':'NH','034':'NH','035':'NH','036':'NH',
  '037':'NH','038':'NH',
  // New Jersey
  '070':'NJ','071':'NJ','072':'NJ','073':'NJ','074':'NJ','075':'NJ','076':'NJ',
  '077':'NJ','078':'NJ','079':'NJ','080':'NJ','081':'NJ','082':'NJ','083':'NJ',
  '084':'NJ','085':'NJ','086':'NJ','087':'NJ','088':'NJ','089':'NJ',
  // New Mexico
  '870':'NM','871':'NM','872':'NM','873':'NM','874':'NM','875':'NM','877':'NM',
  '878':'NM','879':'NM','880':'NM','881':'NM','882':'NM','883':'NM','884':'NM',
  // New York
  '100':'NY','101':'NY','102':'NY','103':'NY','104':'NY','105':'NY','106':'NY',
  '107':'NY','108':'NY','109':'NY','110':'NY','111':'NY','112':'NY','113':'NY',
  '114':'NY','115':'NY','116':'NY','117':'NY','118':'NY','119':'NY','120':'NY',
  '121':'NY','122':'NY','123':'NY','124':'NY','125':'NY','126':'NY','127':'NY',
  '128':'NY','129':'NY','130':'NY','131':'NY','132':'NY','133':'NY','134':'NY',
  '135':'NY','136':'NY','137':'NY','138':'NY','139':'NY','140':'NY','141':'NY',
  '142':'NY','143':'NY','144':'NY','145':'NY','146':'NY','147':'NY','148':'NY',
  '149':'NY',
  // North Carolina
  '270':'NC','271':'NC','272':'NC','273':'NC','274':'NC','275':'NC','276':'NC',
  '277':'NC','278':'NC','279':'NC','280':'NC','281':'NC','282':'NC','283':'NC',
  '284':'NC','285':'NC','286':'NC','287':'NC','288':'NC','289':'NC',
  // North Dakota
  '580':'ND','581':'ND','582':'ND','583':'ND','584':'ND','585':'ND','586':'ND',
  '587':'ND','588':'ND',
  // Ohio
  '430':'OH','431':'OH','432':'OH','433':'OH','434':'OH','435':'OH','436':'OH',
  '437':'OH','438':'OH','439':'OH','440':'OH','441':'OH','442':'OH','443':'OH',
  '444':'OH','445':'OH','446':'OH','447':'OH','448':'OH','449':'OH','450':'OH',
  '451':'OH','452':'OH','453':'OH','454':'OH','455':'OH','456':'OH','457':'OH',
  '458':'OH',
  // Oklahoma
  '730':'OK','731':'OK','733':'OK','734':'OK','735':'OK','736':'OK','737':'OK',
  '738':'OK','739':'OK','740':'OK','741':'OK','743':'OK','744':'OK','745':'OK',
  '746':'OK','747':'OK','748':'OK','749':'OK',
  // Oregon
  '970':'OR','971':'OR','972':'OR','973':'OR','974':'OR','975':'OR','976':'OR',
  '977':'OR','978':'OR','979':'OR',
  // Pennsylvania
  '150':'PA','151':'PA','152':'PA','153':'PA','154':'PA','155':'PA','156':'PA',
  '157':'PA','158':'PA','159':'PA','160':'PA','161':'PA','162':'PA','163':'PA',
  '164':'PA','165':'PA','166':'PA','167':'PA','168':'PA','169':'PA','170':'PA',
  '171':'PA','172':'PA','173':'PA','174':'PA','175':'PA','176':'PA','177':'PA',
  '178':'PA','179':'PA','180':'PA','181':'PA','182':'PA','183':'PA','184':'PA',
  '185':'PA','186':'PA','187':'PA','188':'PA','189':'PA','190':'PA','191':'PA',
  '192':'PA','193':'PA','194':'PA','195':'PA','196':'PA',
  // Rhode Island
  '028':'RI','029':'RI',
  // South Carolina
  '290':'SC','291':'SC','292':'SC','293':'SC','294':'SC','295':'SC','296':'SC',
  '297':'SC','298':'SC','299':'SC',
  // South Dakota
  '570':'SD','571':'SD','572':'SD','573':'SD','574':'SD','575':'SD','576':'SD',
  '577':'SD',
  // Tennessee
  '370':'TN','371':'TN','372':'TN','373':'TN','374':'TN','375':'TN','376':'TN',
  '377':'TN','378':'TN','379':'TN','380':'TN','381':'TN','382':'TN','383':'TN',
  '384':'TN','385':'TN',
  // Texas
  '750':'TX','751':'TX','752':'TX','753':'TX','754':'TX','755':'TX','756':'TX',
  '757':'TX','758':'TX','759':'TX','760':'TX','761':'TX','762':'TX','763':'TX',
  '764':'TX','765':'TX','766':'TX','767':'TX','768':'TX','769':'TX','770':'TX',
  '771':'TX','772':'TX','773':'TX','774':'TX','775':'TX','776':'TX','777':'TX',
  '778':'TX','779':'TX','780':'TX','781':'TX','782':'TX','783':'TX','784':'TX',
  '785':'TX','786':'TX','787':'TX','788':'TX','789':'TX','790':'TX','791':'TX',
  '792':'TX','793':'TX','794':'TX','795':'TX','796':'TX','797':'TX','798':'TX',
  '799':'TX',
  // Utah
  '840':'UT','841':'UT','842':'UT','843':'UT','844':'UT','845':'UT','846':'UT',
  '847':'UT',
  // Vermont
  '050':'VT','051':'VT','052':'VT','053':'VT','054':'VT','055':'VT','056':'VT',
  '057':'VT','058':'VT','059':'VT',
  // Virginia
  '200':'VA','201':'VA','220':'VA','221':'VA','222':'VA','223':'VA','224':'VA',
  '225':'VA','226':'VA','227':'VA','228':'VA','229':'VA','230':'VA','231':'VA',
  '232':'VA','233':'VA','234':'VA','235':'VA','236':'VA','237':'VA','238':'VA',
  '239':'VA','240':'VA','241':'VA','242':'VA','243':'VA','244':'VA','245':'VA',
  '246':'VA',
  // Washington
  '980':'WA','981':'WA','982':'WA','983':'WA','984':'WA','985':'WA','986':'WA',
  '988':'WA','989':'WA','990':'WA','991':'WA','992':'WA','993':'WA','994':'WA',
  // West Virginia
  '247':'WV','248':'WV','249':'WV','250':'WV','251':'WV','252':'WV','253':'WV',
  '254':'WV','255':'WV','256':'WV','257':'WV','258':'WV','259':'WV','260':'WV',
  '261':'WV','262':'WV','263':'WV','264':'WV','265':'WV','266':'WV','267':'WV',
  '268':'WV',
  // Wisconsin
  '530':'WI','531':'WI','532':'WI','534':'WI','535':'WI','537':'WI','538':'WI',
  '539':'WI','540':'WI','541':'WI','542':'WI','543':'WI','544':'WI','545':'WI',
  '546':'WI','547':'WI','548':'WI','549':'WI',
  // Wyoming
  '820':'WY','821':'WY','822':'WY','823':'WY','824':'WY','825':'WY','826':'WY',
  '827':'WY','828':'WY','829':'WY','830':'WY','831':'WY',
};

// ── City / abbreviation → state code ──────────────────────────────────────────
const Map<String, String> _cityToState = {
  // New York
  'new york':'NY','new york city':'NY','nyc':'NY','manhattan':'NY',
  'brooklyn':'NY','queens':'NY','bronx':'NY','staten island':'NY',
  'buffalo':'NY','rochester':'NY','yonkers':'NY','albany':'NY',
  // California
  'los angeles':'CA','la':'CA','hollywood':'CA','santa monica':'CA',
  'long beach':'CA','san diego':'CA','san jose':'CA','san francisco':'CA',
  'sf':'CA','oakland':'CA','berkeley':'CA','sacramento':'CA',
  'fresno':'CA','irvine':'CA','anaheim':'CA','riverside':'CA',
  'stockton':'CA','bakersfield':'CA','san bernardino':'CA',
  // Texas
  'houston':'TX','dallas':'TX','austin':'TX','san antonio':'TX',
  'fort worth':'TX','el paso':'TX','arlington':'TX','corpus christi':'TX',
  'plano':'TX','lubbock':'TX','garland':'TX','irving':'TX','laredo':'TX',
  // Florida
  'miami':'FL','jacksonville':'FL','tampa':'FL','orlando':'FL',
  'fort lauderdale':'FL','st pete':'FL','saint pete':'FL',
  'saint petersburg':'FL','tallahassee':'FL','hialeah':'FL','pensacola':'FL',
  // Illinois
  'chicago':'IL','aurora':'IL','naperville':'IL','joliet':'IL',
  'rockford':'IL','springfield':'IL','peoria':'IL','elgin':'IL',
  // Pennsylvania
  'philadelphia':'PA','philly':'PA','pittsburgh':'PA','allentown':'PA',
  'erie':'PA','reading':'PA','scranton':'PA','bethlehem':'PA',
  // Ohio
  'columbus':'OH','cleveland':'OH','cincinnati':'OH','toledo':'OH',
  'akron':'OH','dayton':'OH','parma':'OH','canton':'OH',
  // Georgia
  'atlanta':'GA','augusta':'GA','columbus ga':'GA','savannah':'GA',
  'athens':'GA','sandy springs':'GA','macon':'GA',
  // North Carolina
  'charlotte':'NC','raleigh':'NC','greensboro':'NC','durham':'NC',
  'winston-salem':'NC','fayetteville':'NC','cary':'NC','wilmington':'NC',
  // Michigan
  'detroit':'MI','grand rapids':'MI','warren':'MI','sterling heights':'MI',
  'ann arbor':'MI','lansing':'MI','flint':'MI','dearborn':'MI',
  // Tennessee
  'nashville':'TN','memphis':'TN','knoxville':'TN','chattanooga':'TN',
  'clarksville':'TN','murfreesboro':'TN','jackson tn':'TN',
  // Washington
  'seattle':'WA','spokane':'WA','tacoma':'WA','vancouver wa':'WA',
  'bellevue':'WA','kent':'WA','everett':'WA','renton':'WA',
  // Massachusetts
  'boston':'MA','worcester':'MA','springfield ma':'MA','cambridge':'MA',
  'lowell':'MA','brockton':'MA','new bedford':'MA','quincy':'MA',
  // Colorado
  'denver':'CO','colorado springs':'CO','aurora co':'CO','fort collins':'CO',
  'lakewood':'CO','thornton':'CO','arvada':'CO','boulder':'CO',
  // Arizona
  'phoenix':'AZ','tucson':'AZ','scottsdale':'AZ','mesa':'AZ',
  'chandler':'AZ','gilbert':'AZ','glendale':'AZ','tempe':'AZ',
  // Indiana
  'indianapolis':'IN','fort wayne':'IN','evansville':'IN','south bend':'IN',
  'carmel':'IN','fishers':'IN','bloomington':'IN','hammond':'IN',
  // Maryland
  'baltimore':'MD','frederick':'MD','rockville':'MD','gaithersburg':'MD',
  // Missouri
  'kansas city':'MO','st. louis':'MO','st louis':'MO','springfield mo':'MO',
  'columbia mo':'MO','independence':'MO',
  // Wisconsin
  'milwaukee':'WI','madison':'WI','green bay':'WI','kenosha':'WI',
  // Oregon
  'portland':'OR','pdx':'OR','eugene':'OR','salem':'OR','gresham':'OR',
  // Nevada
  'las vegas':'NV','henderson':'NV','reno':'NV','north las vegas':'NV',
  // New Mexico
  'albuquerque':'NM','santa fe':'NM','las cruces':'NM',
  // Utah
  'salt lake city':'UT','slc':'UT','west valley city':'UT','provo':'UT',
  'west jordan':'UT','orem':'UT','sandy':'UT',
  // Minnesota
  'minneapolis':'MN','saint paul':'MN','st paul':'MN','rochester mn':'MN',
  'bloomington mn':'MN','duluth':'MN',
  // Louisiana
  'new orleans':'LA','nola':'LA','baton rouge':'LA','shreveport':'LA',
  'metairie':'LA','lafayette la':'LA',
  // Kentucky
  'louisville':'KY','lexington':'KY','bowling green':'KY',
  // Oklahoma
  'oklahoma city':'OK','tulsa':'OK','norman':'OK','broken arrow':'OK',
  // Connecticut
  'bridgeport':'CT','new haven':'CT','hartford':'CT','stamford':'CT',
  // Iowa
  'des moines':'IA','cedar rapids':'IA','davenport':'IA','sioux city':'IA',
  // Kansas
  'wichita':'KS','overland park':'KS','kansas city ks':'KS','topeka':'KS',
  // Mississippi
  'jackson ms':'MS','gulfport':'MS','southaven':'MS','hattiesburg':'MS',
  // Arkansas
  'little rock':'AR','fort smith':'AR','fayetteville ar':'AR','springdale':'AR',
  // Nebraska
  'omaha':'NE','lincoln ne':'NE','bellevue ne':'NE',
  // Virginia
  'virginia beach':'VA','norfolk':'VA','chesapeake':'VA','richmond':'VA',
  'arlington va':'VA','newport news':'VA',
  // New Jersey
  'newark':'NJ','jersey city':'NJ','paterson':'NJ','elizabeth':'NJ',
  'hoboken':'NJ','trenton':'NJ','camden':'NJ',
  // Alabama
  'birmingham':'AL','montgomery':'AL','huntsville':'AL','mobile':'AL',
  // South Carolina
  'charleston':'SC','columbia sc':'SC','north charleston':'SC',
  'mount pleasant':'SC','rock hill':'SC',
  // Other / DC / territories
  'washington':'DC','dc':'DC','honolulu':'HI','anchorage':'AK',
  'boise':'ID','helena':'MT','bismarck':'ND','pierre':'SD',
  'cheyenne':'WY','charleston wv':'WV',
  // Additional Alabama
  'tuscaloosa':'AL','dothan':'AL','hoover':'AL','decatur':'AL',
  'auburn':'AL','gadsden':'AL','phenix city':'AL','madison al':'AL',
  // Additional Alaska
  'fairbanks':'AK','juneau':'AK','sitka':'AK','ketchikan':'AK',
  // Additional Arizona
  'peoria az':'AZ','surprise az':'AZ','goodyear':'AZ','yuma':'AZ',
  'avondale':'AZ','flagstaff':'AZ','prescott':'AZ','lake havasu city':'AZ',
  // Additional Arkansas
  'jonesboro':'AR','north little rock':'AR','conway':'AR','rogers':'AR',
  'bentonville':'AR','pine bluff':'AR','hot springs':'AR',
  // Additional California
  'modesto':'CA','chula vista':'CA','oxnard':'CA','garden grove':'CA',
  'oceanside':'CA','ontario ca':'CA','corona':'CA','moreno valley':'CA',
  'glendale ca':'CA','escondido':'CA','salinas':'CA','thousand oaks':'CA',
  'sunnyvale':'CA','simi valley':'CA','concord ca':'CA','santa clarita':'CA',
  'el monte':'CA','roseville':'CA','torrance':'CA','pomona':'CA',
  'hayward':'CA','fremont':'CA','pasadena':'CA','orange ca':'CA',
  'fullerton':'CA','fontana':'CA','rancho cucamonga':'CA','santa rosa':'CA',
  'lancaster':'CA','palmdale':'CA','salinas ca':'CA','visalia':'CA',
  'joliet ca':'CA','victorville':'CA','santa clara':'CA','los gatos':'CA',
  'murrieta':'CA','temecula':'CA','elk grove':'CA','antioch ca':'CA',
  'inglewood':'CA','ventura':'CA','norwalk ca':'CA','burbank':'CA',
  // Additional Colorado
  'pueblo co':'CO','westminster co':'CO','highlands ranch':'CO',
  'centennial co':'CO','greeley':'CO','longmont':'CO','loveland co':'CO',
  'broomfield':'CO','castle rock':'CO','commerce city':'CO',
  'parker co':'CO','northglenn':'CO','brighton co':'CO',
  // Additional Connecticut
  'danbury':'CT','norwalk ct':'CT','waterbury':'CT','west haven':'CT',
  'milford ct':'CT','meriden':'CT','groton':'CT','new britain':'CT',
  // Additional Delaware
  'dover':'DE','newark de':'DE','middletown de':'DE','smyrna de':'DE',
  // Additional Florida
  'gainesville':'FL','clearwater':'FL','cape coral':'FL','bonita springs':'FL',
  'lakeland':'FL','pompano beach':'FL','west palm beach':'FL','miramar':'FL',
  'palm bay':'FL','daytona beach':'FL','port st lucie':'FL',
  'sunrise fl':'FL','coral springs':'FL','hollywood fl':'FL',
  'pembroke pines':'FL','brandon':'FL','kissimmee':'FL','deltona':'FL',
  'st cloud fl':'FL','palm coast':'FL','spring hill':'FL','melbourne fl':'FL',
  'deerfield beach':'FL','ocala':'FL','fort myers':'FL','boca raton':'FL',
  'sarasota':'FL','naples fl':'FL','boynton beach':'FL','largo':'FL',
  // Additional Georgia
  'roswell':'GA','marietta':'GA','warner robins':'GA','albany ga':'GA',
  'smyrna ga':'GA','johns creek':'GA','stonecrest':'GA','rome ga':'GA',
  'peachtree city':'GA','alpharetta':'GA','gainesville ga':'GA',
  'valdosta':'GA','brookhaven':'GA','dunwoody':'GA',
  // Additional Hawaii
  'pearl city':'HI','waipahu':'HI','kaneohe':'HI','kailua hi':'HI',
  'hilo':'HI','kihei':'HI','maui':'HI','kahului':'HI',
  // Additional Idaho
  'nampa':'ID','meridian':'ID','idaho falls':'ID','caldwell':'ID',
  'pocatello':'ID','coeur d alene':'ID','twin falls':'ID',
  // Additional Illinois
  'waukegan':'IL','cicero':'IL','champaign':'IL','arlington heights il':'IL',
  'evanston':'IL','decatur il':'IL','schaumburg':'IL','bolingbrook':'IL',
  'palatine':'IL','skokie':'IL','des plaines':'IL','orland park':'IL',
  'tinley park':'IL','oak lawn':'IL','berwyn':'IL','mount prospect':'IL',
  'normal':'IL','bloomington il':'IL','moline':'IL','galesburg':'IL',
  // Additional Indiana
  'noblesville':'IN','greenwood in':'IN','anderson in':'IN','terre haute':'IN',
  'muncie':'IN','lafayette in':'IN','westfield in':'IN','kokomo':'IN',
  'michigan city':'IN','richmond in':'IN','new albany':'IN','jeffersonville':'IN',
  // Additional Iowa
  'ames':'IA','council bluffs':'IA','ankeny':'IA','west des moines':'IA',
  'urbandale':'IA','dubuque':'IA','iowa city':'IA','waterloo':'IA',
  // Additional Kansas
  'olathe':'KS','manhattan ks':'KS',
  'salina':'KS','hutchinson':'KS','leavenworth':'KS','shawnee ks':'KS',
  // Additional Kentucky
  'owensboro':'KY','covington ky':'KY','hopkinsville':'KY','richmond ky':'KY',
  'florence ky':'KY','elizabethtown':'KY','frankfort':'KY','henderson ky':'KY',
  // Additional Louisiana
  'kenner':'LA','bossier city':'LA','lake charles':'LA','monroe la':'LA',
  'alexandria la':'LA','houma':'LA','slidell':'LA','marrero':'LA',
  // Additional Maine
  'lewiston':'ME','bangor':'ME','south portland':'ME','auburn me':'ME',
  'biddeford':'ME','sanford me':'ME','augusta me':'ME',
  // Additional Maryland
  'columbia md':'MD','silverspring':'MD','silver spring':'MD','waldorf':'MD',
  'glen burnie':'MD','ellicott city':'MD','dundalk':'MD','bethesda':'MD',
  'germantown md':'MD','towson':'MD','bowie':'MD','annapolis':'MD',
  'college park md':'MD','bel air':'MD','laurel md':'MD',
  // Additional Massachusetts
  'taunton':'MA','lynn':'MA','waltham':'MA','haverhill':'MA','malden':'MA',
  'medford ma':'MA','chicopee':'MA','weymouth':'MA','revere':'MA',
  'peabody':'MA','methuen':'MA','attleboro':'MA','newton ma':'MA',
  'somerville':'MA','lawrence ma':'MA','fall river':'MA',
  // Additional Michigan
  'westland':'MI','clinton township':'MI','canton mi':'MI','taylor mi':'MI',
  'royal oak':'MI','pontiac mi':'MI','novi':'MI','kalamazoo':'MI',
  'southfield':'MI','dearborn heights':'MI','wyoming mi':'MI',
  'battle creek':'MI','jackson mi':'MI','muskegon':'MI','bay city':'MI',
  'traverse city':'MI','midland mi':'MI','saginaw':'MI','portage mi':'MI',
  // Additional Minnesota
  'plymouth mn':'MN','maple grove':'MN','woodbury':'MN','eagan':'MN',
  'burnsville':'MN','brooklyn park':'MN','coon rapids':'MN','eden prairie':'MN',
  'blaine':'MN','lakeville mn':'MN','minnetonka':'MN','st cloud':'MN',
  'mankato':'MN','maplewood mn':'MN','moorhead':'MN','apple valley mn':'MN',
  // Additional Mississippi
  'biloxi':'MS','olive branch':'MS','tupelo':'MS',
  'columbus ms':'MS','madison ms':'MS','starkville':'MS',
  // Additional Missouri
  'lee summit':'MO','ofallon mo':'MO','saint charles mo':'MO',
  'saint joseph':'MO','blue springs':'MO','joplin':'MO',
  'florissant':'MO','raytown':'MO','chesterfield mo':'MO','ballwin':'MO',
  // Additional Montana
  'billings':'MT','great falls':'MT','missoula':'MT','bozeman':'MT',
  'butte':'MT','kalispell':'MT','havre':'MT',
  // Additional Nebraska
  'grand island':'NE','kearney':'NE','fremont ne':'NE','hastings ne':'NE',
  'north platte':'NE','norfolk ne':'NE',
  // Additional Nevada
  'sparks':'NV','enterprise nv':'NV','spring valley nv':'NV',
  'sunrise manor':'NV','whitney nv':'NV','paradise nv':'NV',
  'carson city':'NV','elko':'NV',
  // Additional New Hampshire
  'nashua':'NH','concord nh':'NH','derry':'NH','rochester nh':'NH',
  'dover nh':'NH','merrimack':'NH','londonderry':'NH',
  // Additional New Jersey
  'woodbridge nj':'NJ','hamilton nj':'NJ','edison nj':'NJ',
  'toms river':'NJ','clifton':'NJ','cherry hill':'NJ','brick nj':'NJ',
  'passaic':'NJ','middletown nj':'NJ','union city nj':'NJ',
  'gloucester township':'NJ','ocean township':'NJ','bayonne':'NJ',
  // Additional New Mexico
  'rio rancho':'NM','roswell nm':'NM','alamogordo':'NM','clovis nm':'NM',
  'carlsbad nm':'NM','hobbs':'NM','farmington nm':'NM',
  // Additional New York
  'syracuse':'NY','troy ny':'NY','utica':'NY','white plains':'NY',
  'new rochelle':'NY','mount vernon ny':'NY','schenectady':'NY',
  'niagara falls ny':'NY','binghamton':'NY','long island':'NY',
  'hempstead':'NY','freeport ny':'NY','amherst ny':'NY',
  'cheektowaga':'NY','spring valley ny':'NY','valley stream':'NY',
  // Additional North Carolina
  'gastonia':'NC','concord nc':'NC','high point':'NC','greenville nc':'NC',
  'jacksonville nc':'NC','huntersville':'NC','chapel hill':'NC',
  'mooresville':'NC','burlington nc':'NC','wilson nc':'NC',
  'rocky mount':'NC','kannapolis':'NC','apex nc':'NC','hickory':'NC',
  // Additional North Dakota
  'grand forks':'ND','minot':'ND',
  'mandan':'ND','west fargo':'ND','jamestown nd':'ND',
  // Additional Ohio
  'hamilton oh':'OH','lorain':'OH','springfield oh':'OH','lakewood oh':'OH',
  'elyria':'OH','newark oh':'OH','kettering':'OH','mentor oh':'OH',
  'cuyahoga falls':'OH','fairfield oh':'OH','middletown oh':'OH',
  'euclid':'OH','mansfield oh':'OH','beavercreek':'OH','strongsville':'OH',
  'dublin oh':'OH','grove city':'OH','westerville':'OH','reynoldsburg':'OH',
  // Additional Oklahoma
  'lawton':'OK','edmond':'OK','moore':'OK','midwest city':'OK',
  'enid':'OK','stillwater':'OK','muskogee':'OK','owasso':'OK','sapulpa':'OK',
  // Additional Oregon
  'beaverton':'OR','hillsboro':'OR','bend':'OR','medford':'OR',
  'springfield or':'OR','corvallis':'OR','albany or':'OR','tigard':'OR',
  'lake oswego':'OR','keizer':'OR','grants pass':'OR','roseburg':'OR',
  // Additional Pennsylvania
  'levittown':'PA','altoona':'PA','harrisburg':'PA','wilkes barre':'PA',
  'chester':'PA','york pa':'PA','ambridge':'PA','monroeville':'PA',
  'abington':'PA','lower merion':'PA','bensalem':'PA','norristown':'PA',
  // Additional Rhode Island
  'providence':'RI','cranston':'RI','pawtucket':'RI','warwick':'RI',
  'east providence':'RI','woonsocket':'RI',
  // Additional South Carolina
  'summerville':'SC','goose creek':'SC','hilton head island':'SC',
  'sumter':'SC','florence sc':'SC','spartanburg':'SC','anderson sc':'SC',
  'myrtle beach':'SC',
  // Additional South Dakota
  'sioux falls':'SD','rapid city':'SD','aberdeen sd':'SD','brookings':'SD',
  'watertown sd':'SD','mitchell sd':'SD',
  // Additional Tennessee
  'franklin tn':'TN','hendersonville':'TN','brentwood tn':'TN','smyrna tn':'TN',
  'collierville':'TN','bartlett':'TN','johnson city':'TN','kingsport':'TN',
  'maryville tn':'TN','columbia tn':'TN','gallatin tn':'TN','spring hill tn':'TN',
  // Additional Texas
  'pasadena tx':'TX','mesquite':'TX','frisco':'TX','mckinney':'TX',
  'killeen':'TX','denton':'TX','midland':'TX','odessa':'TX',
  'abilene':'TX','beaumont':'TX','round rock':'TX','lewisville':'TX',
  'carrollton':'TX','pearland':'TX','richardson':'TX','league city':'TX',
  'wichita falls':'TX','allen tx':'TX','sugar land':'TX','edinburg':'TX',
  'mission tx':'TX','pharr':'TX','waco':'TX','tyler tx':'TX',
  'college station':'TX','amarillo':'TX','grand prairie':'TX','brownsville':'TX',
  'mcallen':'TX','new braunfels':'TX','the woodlands':'TX','conroe':'TX',
  'texas city':'TX','temple tx':'TX','longview tx':'TX','port arthur':'TX',
  // Additional Utah
  'st george':'UT','layton':'UT','south jordan':'UT','millcreek':'UT',
  'taylorsville':'UT','murray ut':'UT','lehi':'UT','herriman':'UT',
  'logan ut':'UT','draper':'UT','bountiful ut':'UT','cottonwood heights':'UT',
  // Additional Vermont
  'burlington vt':'VT','south burlington':'VT','colchester vt':'VT',
  'rutland':'VT','essex vt':'VT','bennington':'VT',
  // Additional Virginia
  'roanoke':'VA','hampton':'VA','alexandria':'VA','suffolk':'VA',
  'harrisonburg':'VA','charlottesville':'VA','fredericksburg':'VA',
  'leesburg':'VA','herndon':'VA','reston':'VA','manassas':'VA',
  'lynchburg':'VA','danville va':'VA','portsmouth va':'VA',
  // Additional Washington
  'marysville wa':'WA','lakewood wa':'WA','shoreline':'WA','kirkland':'WA',
  'federal way':'WA','redmond wa':'WA','bellingham':'WA','kennewick':'WA',
  'pasco':'WA','richland':'WA','sammamish':'WA','burien':'WA',
  'olympia':'WA','auburn wa':'WA','south hill wa':'WA','yakima':'WA',
  // Additional West Virginia
  'huntington':'WV','parkersburg':'WV','morgantown':'WV','wheeling':'WV',
  'martinsburg':'WV','clarksburg':'WV',
  // Additional Wisconsin
  'appleton':'WI','racine':'WI','waukesha':'WI','oshkosh':'WI',
  'eau claire':'WI','janesville':'WI','west allis':'WI','la crosse':'WI',
  'sheboygan':'WI','wauwatosa':'WI','fond du lac':'WI','brookfield wi':'WI',
  'beloit':'WI','greenfield wi':'WI','wausau':'WI','new berlin':'WI',
  // Additional Wyoming
  'casper':'WY','laramie':'WY','gillette':'WY','rock springs':'WY',
  'sheridan wy':'WY','green river':'WY','evanston wy':'WY',
};

// ── State name → state abbreviation ───────────────────────────────────────────
const Map<String, String> _stateNameToCode = {
  'alabama':'AL','alaska':'AK','arizona':'AZ','arkansas':'AR',
  'california':'CA','colorado':'CO','connecticut':'CT','delaware':'DE',
  'florida':'FL','georgia':'GA','hawaii':'HI','idaho':'ID',
  'illinois':'IL','indiana':'IN','iowa':'IA','kansas':'KS',
  'kentucky':'KY','louisiana':'LA','maine':'ME','maryland':'MD',
  'massachusetts':'MA','michigan':'MI','minnesota':'MN','mississippi':'MS',
  'missouri':'MO','montana':'MT','nebraska':'NE','nevada':'NV',
  'new hampshire':'NH','new jersey':'NJ','new mexico':'NM','new york':'NY',
  'north carolina':'NC','north dakota':'ND','ohio':'OH','oklahoma':'OK',
  'oregon':'OR','pennsylvania':'PA','rhode island':'RI','south carolina':'SC',
  'south dakota':'SD','tennessee':'TN','texas':'TX','utah':'UT',
  'vermont':'VT','virginia':'VA','washington':'WA','west virginia':'WV',
  'wisconsin':'WI','wyoming':'WY','district of columbia':'DC',
};

// ── Location resolution ────────────────────────────────────────────────────────

/// Resolves a zip code / city / state input to a [_ResolvedLocation].
/// Returns null only when the input is completely unrecognisable (e.g. random
/// letters that match no known place). In practice this almost never happens.
_ResolvedLocation? _resolveLocation(String input) {
  final lower = input.toLowerCase().trim();
  final digits = lower.replaceAll(RegExp(r'\D'), '');

  // 1. Numeric zip code — resolve prefix to state and look up canonical city name
  if (digits.length >= 3) {
    final prefix = digits.substring(0, 3);
    final state = _zipPrefixToState[prefix];
    if (state != null) {
      // Find the canonical city for this zip prefix via reverse lookup in _cityToState
      final city = _zipToCity[prefix] ?? _capitalForState(state);
      return _ResolvedLocation(city: city, state: state, zip: input.trim());
    }
  }

  // 2. Exact 2-letter state abbreviation → return state capital
  final upper = input.trim().toUpperCase();
  if (upper.length == 2 && _stateNameToCode.values.contains(upper)) {
    return _ResolvedLocation(city: _capitalForState(upper), state: upper, zip: '');
  }

  // 3. Full state name
  final stateCode = _stateNameToCode[lower];
  if (stateCode != null) {
    return _ResolvedLocation(city: _capitalForState(stateCode), state: stateCode, zip: '');
  }

  // 4. City name lookup (longest match first so "new york city" beats "york")
  final sortedCities = _cityToState.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final city in sortedCities) {
    if (lower == city || lower.startsWith('$city ') || lower.endsWith(' $city') || lower.contains(' $city ')) {
      final st = _cityToState[city]!;
      // Capitalise words for display
      final displayCity = city.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
      return _ResolvedLocation(city: displayCity, state: st, zip: '');
    }
  }

  // 5. Partial / substring city match as last resort
  for (final city in sortedCities) {
    if (lower.contains(city)) {
      final st = _cityToState[city]!;
      final displayCity = city.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
      return _ResolvedLocation(city: displayCity, state: st, zip: '');
    }
  }

  return null;
}

class _ResolvedLocation {
  final String city;
  final String state;
  final String zip;
  const _ResolvedLocation({required this.city, required this.state, required this.zip});
}

/// Returns the largest / capital city for a given state code.
String _capitalForState(String stateCode) {
  const map = {
    'AL':'Birmingham','AK':'Anchorage','AZ':'Phoenix','AR':'Little Rock',
    'CA':'Los Angeles','CO':'Denver','CT':'Hartford','DE':'Wilmington',
    'FL':'Miami','GA':'Atlanta','HI':'Honolulu','ID':'Boise',
    'IL':'Chicago','IN':'Indianapolis','IA':'Des Moines','KS':'Wichita',
    'KY':'Louisville','LA':'New Orleans','ME':'Portland','MD':'Baltimore',
    'MA':'Boston','MI':'Detroit','MN':'Minneapolis','MS':'Jackson',
    'MO':'Kansas City','MT':'Billings','NE':'Omaha','NV':'Las Vegas',
    'NH':'Manchester','NJ':'Newark','NM':'Albuquerque','NY':'New York',
    'NC':'Charlotte','ND':'Fargo','OH':'Columbus','OK':'Oklahoma City',
    'OR':'Portland','PA':'Philadelphia','RI':'Providence','SC':'Charleston',
    'SD':'Sioux Falls','TN':'Nashville','TX':'Houston','UT':'Salt Lake City',
    'VT':'Burlington','VA':'Virginia Beach','WA':'Seattle','WV':'Charleston',
    'WI':'Milwaukee','WY':'Cheyenne','DC':'Washington',
  };
  return map[stateCode] ?? stateCode;
}

// ── Zip prefix → canonical city name ──────────────────────────────────────────
// Covers common 3-digit zip prefixes → the primary city served by that prefix.
// This is what makes "79912" resolve to "El Paso" rather than just "TX".
const Map<String, String> _zipToCity = {
  // Alabama
  '350':'Birmingham','351':'Birmingham','352':'Birmingham','354':'Tuscaloosa',
  '355':'Tuscaloosa','356':'Decatur','357':'Huntsville','358':'Huntsville',
  '359':'Gadsden','360':'Montgomery','361':'Montgomery','362':'Anniston',
  '363':'Dothan','364':'Dothan','365':'Mobile','366':'Mobile','367':'Selma',
  '368':'Mobile','369':'Mobile',
  // Alaska
  '995':'Anchorage','996':'Fairbanks','997':'Fairbanks','998':'Juneau','999':'Ketchikan',
  // Arizona
  '850':'Phoenix','851':'Phoenix','852':'Phoenix','853':'Phoenix',
  '855':'Mesa','856':'Tucson','857':'Tucson','859':'Yuma','860':'Flagstaff',
  '863':'Prescott','864':'Flagstaff','865':'Flagstaff',
  // Arkansas
  '716':'Texarkana','717':'Camden','718':'El Dorado','719':'Hot Springs',
  '720':'Little Rock','721':'Little Rock','722':'Little Rock',
  '723':'Jonesboro','724':'Jonesboro','725':'Conway','726':'Harrison',
  '727':'Fort Smith','728':'Fort Smith','729':'Fort Smith',
  // California
  '900':'Los Angeles','901':'Los Angeles','902':'Inglewood',
  '903':'Los Angeles','904':'Santa Monica','905':'Torrance',
  '906':'Long Beach','907':'Long Beach','908':'Long Beach',
  '910':'Glendale','911':'Pasadena','912':'Burbank',
  '913':'Van Nuys','914':'Van Nuys','915':'Pomona',
  '916':'Pomona','917':'Covina','918':'Covina',
  '919':'San Diego','920':'San Diego','921':'San Diego',
  '922':'San Bernardino','923':'San Bernardino','924':'San Bernardino',
  '925':'Riverside','926':'Anaheim','927':'Santa Ana','928':'Irvine',
  '930':'Oxnard','931':'Santa Barbara','932':'Bakersfield',
  '933':'Bakersfield','934':'San Luis Obispo','935':'Fresno',
  '936':'Fresno','937':'Fresno','938':'Fresno',
  '939':'Salinas','940':'San Francisco','941':'San Francisco',
  '942':'Sacramento','943':'Palo Alto','944':'Oakland',
  '945':'Oakland','946':'Oakland','947':'Berkeley',
  '948':'Richmond','949':'San Rafael','950':'San Jose',
  '951':'San Jose','952':'San Jose','953':'Santa Cruz',
  '954':'Santa Rosa','955':'Eureka','956':'Sacramento',
  '957':'Sacramento','958':'Sacramento','959':'Marysville',
  '960':'Redding','961':'Reno',
  // Colorado
  '800':'Denver','801':'Denver','802':'Denver','803':'Aurora',
  '804':'Aurora','805':'Lakewood','806':'Boulder','807':'Boulder',
  '808':'Colorado Springs','809':'Colorado Springs','810':'Pueblo','811':'Pueblo',
  '812':'Pueblo','813':'Fort Collins','814':'Fort Collins',
  '815':'Fort Collins','816':'Grand Junction',
  // Connecticut
  '060':'New Haven','061':'Hartford','062':'New Haven',
  '063':'Bridgeport','064':'New Haven','065':'New Haven',
  '066':'Bridgeport','067':'Waterbury','068':'Stamford','069':'Norwalk',
  // Delaware
  '197':'Wilmington','198':'Wilmington','199':'Dover',
  // Florida
  '320':'Jacksonville','321':'Daytona Beach','322':'Jacksonville',
  '323':'Tallahassee','324':'Pensacola','325':'Pensacola',
  '326':'Gainesville','327':'Orlando','328':'Orlando','329':'Orlando',
  '330':'Miami','331':'Miami','332':'Miami','333':'Fort Lauderdale',
  '334':'Fort Lauderdale','335':'Tampa','336':'Tampa','337':'Tampa',
  '338':'Tampa','339':'Fort Myers','341':'Sarasota',
  '342':'Sarasota','344':'Daytona Beach','346':'Tampa',
  '347':'Orlando','349':'Fort Myers',
  // Georgia
  '300':'Atlanta','301':'Atlanta','302':'Atlanta','303':'Atlanta',
  '304':'Atlanta','305':'Atlanta','306':'Athens',
  '307':'Savannah','308':'Augusta','309':'Augusta',
  '310':'Macon','311':'Macon','312':'Columbus',
  '313':'Savannah','314':'Savannah','315':'Savannah',
  '316':'Macon','317':'Atlanta','318':'Atlanta','319':'Athens',
  // Hawaii
  '967':'Honolulu','968':'Hilo',
  // Idaho
  '832':'Boise','833':'Boise','834':'Boise','835':'Boise',
  '836':'Boise','837':'Twin Falls','838':'Pocatello','839':'Coeur D Alene',
  // Illinois
  '600':'Chicago','601':'Chicago','602':'Chicago','603':'Chicago',
  '604':'Chicago','605':'Chicago','606':'Chicago',
  '607':'Chicago','608':'Chicago','609':'Chicago',
  '610':'Rockford','611':'Rockford','612':'Rockford',
  '613':'La Salle','614':'Peoria','615':'Peoria',
  '616':'Peoria','617':'Bloomington','618':'Champaign',
  '619':'Champaign','620':'East St Louis','621':'East St Louis',
  '622':'East St Louis','623':'Springfield','624':'Quincy',
  '625':'Quincy','626':'Springfield','627':'Springfield',
  '628':'Carbondale','629':'Carbondale',
  // Indiana
  '460':'Indianapolis','461':'Indianapolis','462':'Indianapolis',
  '463':'Gary','464':'Gary','465':'Gary','466':'Gary',
  '467':'Fort Wayne','468':'Fort Wayne','469':'Fort Wayne',
  '470':'Kokomo','471':'Kokomo','472':'Kokomo',
  '473':'Muncie','474':'Bloomington','475':'Terre Haute',
  '476':'Evansville','477':'Evansville','478':'Terre Haute',
  '479':'South Bend',
  // Iowa
  '500':'Des Moines','501':'Des Moines','502':'Des Moines',
  '503':'Des Moines','504':'Des Moines','505':'Fort Dodge',
  '506':'Waterloo','507':'Waterloo','508':'Waterloo',
  '510':'Sioux City','511':'Sioux City','512':'Sioux City',
  '513':'Spencer','514':'Carroll','515':'Des Moines',
  '516':'Shenandoah','520':'Dubuque','521':'Dubuque',
  '522':'Iowa City','523':'Iowa City','524':'Iowa City',
  '525':'Iowa City','526':'Burlington','527':'Burlington',
  '528':'Burlington',
  // Kansas
  '660':'Kansas City','661':'Kansas City','662':'Kansas City',
  '664':'Topeka','665':'Topeka','666':'Salina',
  '667':'Wichita','668':'Wichita','669':'Wichita',
  '670':'Wichita','671':'Wichita','672':'Wichita',
  '673':'Independence','674':'Emporia','675':'Hutchinson',
  '676':'Hutchinson','677':'Hutchinson','678':'Garden City',
  '679':'Liberal',
  // Kentucky
  '400':'Louisville','401':'Louisville','402':'Louisville',
  '403':'Louisville','404':'Lexington','405':'Lexington',
  '406':'Frankfort','407':'Morehead','408':'Morehead',
  '409':'Corbin','410':'Louisville','411':'Pikeville',
  '412':'Ashland','413':'Ashland','414':'Pikeville',
  '415':'Paintsville','416':'Prestonsburg','417':'Hazard',
  '418':'Hazard',
  // Louisiana
  '700':'New Orleans','701':'New Orleans','703':'Baton Rouge',
  '704':'Baton Rouge','705':'Lafayette','706':'Lake Charles',
  '707':'Baton Rouge','708':'Houma','710':'Shreveport',
  '711':'Shreveport','712':'Shreveport','713':'Monroe','714':'Monroe',
  // Maine
  '039':'Bath','040':'Portland','041':'Portland','042':'Portland',
  '043':'Augusta','044':'Bangor','045':'Bangor','046':'Rockland',
  '047':'Houlton','048':'Lewiston','049':'Lewiston',
  // Maryland
  '206':'Waldorf','207':'Rockville','208':'Gaithersburg',
  '209':'Annapolis','210':'Baltimore','211':'Baltimore',
  '212':'Baltimore','214':'Baltimore','215':'Cumberland',
  '216':'Salisbury','217':'Frederick','218':'Hagerstown','219':'Westminster',
  // Massachusetts
  '010':'Springfield','011':'Springfield','012':'Pittsfield',
  '013':'Northampton','014':'Fitchburg','015':'Worcester',
  '016':'Worcester','017':'Framingham','018':'Lowell','019':'Lynn',
  '020':'Boston','021':'Boston','022':'Boston','023':'Brockton',
  '024':'Brockton','025':'Cape Cod','026':'Cape Cod','027':'New Bedford',
  // Michigan
  '480':'Detroit','481':'Detroit','482':'Detroit','483':'Detroit',
  '484':'Flint','485':'Flint','486':'Saginaw','487':'Saginaw',
  '488':'Lansing','489':'Lansing','490':'Battle Creek',
  '491':'Battle Creek','492':'Kalamazoo','493':'Grand Rapids',
  '494':'Grand Rapids','495':'Grand Rapids','496':'Traverse City',
  '497':'Petoskey','498':'Iron Mountain','499':'Marquette',
  // Minnesota
  '550':'Minneapolis','551':'Saint Paul','553':'Minneapolis',
  '554':'Minneapolis','555':'Minneapolis','556':'Duluth',
  '557':'Duluth','558':'Rochester','559':'Winona',
  '560':'St Cloud','561':'St Cloud','562':'Willmar',
  '563':'Mankato','564':'Mankato','565':'Bemidji',
  '566':'Brainerd','567':'Moorhead',
  // Mississippi
  '386':'Clarksdale','387':'Greenville','388':'Greenville',
  '389':'Greenwood','390':'Jackson','391':'Jackson',
  '392':'Jackson','393':'Meridian','394':'Laurel',
  '395':'Hattiesburg','396':'Gulfport','397':'Pascagoula',
  // Missouri
  '630':'St Louis','631':'St Louis','633':'St Louis',
  '634':'Hannibal','635':'Kirksville','636':'Cape Girardeau',
  '637':'Cape Girardeau','638':'Poplar Bluff','639':'Poplar Bluff',
  '640':'Kansas City','641':'Kansas City','644':'Kansas City',
  '645':'Kansas City','646':'Chillicothe','647':'Chillicothe',
  '648':'Joplin','649':'Joplin','650':'Jefferson City',
  '651':'Jefferson City','652':'Jefferson City','653':'Rolla',
  '654':'Springfield','655':'Springfield','656':'Springfield',
  '657':'Springfield','658':'Joplin',
  // Montana
  '590':'Billings','591':'Billings','592':'Great Falls',
  '593':'Helena','594':'Great Falls','595':'Havre',
  '596':'Miles City','597':'Glendive','598':'Missoula','599':'Missoula',
  // Nebraska
  '680':'Omaha','681':'Omaha','683':'Lincoln','684':'Lincoln',
  '685':'Lincoln','686':'Lincoln','687':'Norfolk',
  '688':'Grand Island','689':'Hastings','690':'McCook',
  '691':'North Platte','692':'North Platte','693':'Alliance',
  // Nevada
  '889':'Las Vegas','890':'Las Vegas','891':'Las Vegas',
  '893':'Las Vegas','894':'Reno','895':'Reno','897':'Reno','898':'Elko',
  // New Hampshire
  '030':'Manchester','031':'Manchester','032':'Concord',
  '033':'Concord','034':'Keene','035':'Keene','036':'Claremont',
  '037':'Nashua','038':'Portsmouth',
  // New Jersey
  '070':'Newark','071':'Newark','072':'Elizabeth','073':'Jersey City',
  '074':'Paterson','075':'Paterson','076':'Hackensack',
  '077':'Long Branch','078':'Dover','079':'Summit','080':'Trenton',
  '081':'Trenton','082':'Atlantic City','083':'Atlantic City',
  '084':'Atlantic City','085':'Trenton','086':'Trenton',
  '087':'Princeton','088':'New Brunswick','089':'New Brunswick',
  // New Mexico
  '870':'Albuquerque','871':'Albuquerque','872':'Albuquerque',
  '873':'Albuquerque','874':'Farmington','875':'Santa Fe',
  '877':'Las Cruces','878':'Las Cruces','879':'Las Cruces',
  '880':'Las Cruces','881':'Las Cruces','882':'Roswell',
  '883':'Carlsbad','884':'Clovis',
  // New York
  '100':'New York','101':'New York','102':'New York','103':'Staten Island',
  '104':'Bronx','105':'Yonkers','106':'White Plains','107':'Yonkers',
  '108':'New Rochelle','109':'Poughkeepsie','110':'Jamaica',
  '111':'Long Island City','112':'Brooklyn','113':'Flushing',
  '114':'Jamaica','115':'Jamaica','116':'Far Rockaway','117':'Hempstead',
  '118':'Mineola','119':'Mineola','120':'Albany','121':'Albany',
  '122':'Albany','123':'Schenectady','124':'Kingston',
  '125':'Poughkeepsie','126':'Middletown','127':'Newburgh',
  '128':'Saratoga Springs','129':'Glens Falls','130':'Syracuse',
  '131':'Syracuse','132':'Syracuse','133':'Utica','134':'Binghamton',
  '135':'Binghamton','136':'Watertown','137':'Elmira',
  '138':'Ithaca','139':'Ithaca','140':'Buffalo','141':'Buffalo',
  '142':'Buffalo','143':'Niagara Falls','144':'Rochester',
  '145':'Rochester','146':'Rochester','147':'Rochester',
  '148':'Ithaca','149':'Ithaca',
  // North Carolina
  '270':'Greensboro','271':'Winston-Salem','272':'Greensboro',
  '273':'Durham','274':'Durham','275':'Raleigh','276':'Raleigh',
  '277':'Raleigh','278':'Rocky Mount','279':'Rocky Mount',
  '280':'Charlotte','281':'Charlotte','282':'Charlotte',
  '283':'Fayetteville','284':'Fayetteville','285':'Wilmington',
  '286':'Asheville','287':'Asheville','288':'Asheville','289':'Hickory',
  // North Dakota
  '580':'Fargo','581':'Fargo','582':'Grand Forks','583':'Minot',
  '584':'Minot','585':'Bismarck','586':'Bismarck',
  '587':'Dickinson','588':'Jamestown',
  // Ohio
  '430':'Columbus','431':'Columbus','432':'Columbus','433':'Columbus',
  '434':'Toledo','435':'Toledo','436':'Toledo','437':'Zanesville',
  '438':'Cambridge','439':'Steubenville','440':'Cleveland',
  '441':'Cleveland','442':'Cleveland','443':'Cleveland',
  '444':'Youngstown','445':'Youngstown','446':'Akron',
  '447':'Akron','448':'Akron','449':'Canton','450':'Cincinnati',
  '451':'Cincinnati','452':'Cincinnati','453':'Dayton',
  '454':'Dayton','455':'Dayton','456':'Columbus','457':'Athens',
  '458':'Lima',
  // Oklahoma
  '730':'Oklahoma City','731':'Oklahoma City','733':'Oklahoma City',
  '734':'Ardmore','735':'Lawton','736':'Lawton',
  '737':'Clinton','738':'Enid','739':'Enid','740':'Tulsa',
  '741':'Tulsa','743':'Tulsa','744':'Tulsa','745':'Muskogee',
  '746':'Bartlesville','747':'Ponca City','748':'Stillwater','749':'Durant',
  // Oregon
  '970':'Portland','971':'Portland','972':'Portland','973':'Portland',
  '974':'Eugene','975':'Salem','976':'Portland','977':'Medford',
  '978':'Corvallis','979':'Klamath Falls',
  // Pennsylvania
  '150':'Pittsburgh','151':'Pittsburgh','152':'Pittsburgh',
  '153':'Pittsburgh','154':'Pittsburgh','155':'Uniontown',
  '156':'Greensburg','157':'Indiana','158':'Dubois',
  '159':'Johnstown','160':'New Castle','161':'Butler',
  '162':'Kittanning','163':'Oil City','164':'Erie','165':'Erie',
  '166':'Altoona','167':'Harrisburg','168':'Harrisburg',
  '169':'Harrisburg','170':'Harrisburg','171':'York',
  '172':'York','173':'Lancaster','174':'Lancaster',
  '175':'Lancaster','176':'Reading','177':'Reading',
  '178':'Scranton','179':'Scranton','180':'Allentown',
  '181':'Allentown','182':'Allentown','183':'Stroudsburg',
  '184':'Stroudsburg','185':'Hazleton','186':'Wilkes-Barre',
  '187':'Wilkes-Barre','188':'Williamsport','189':'Pottsville',
  '190':'Philadelphia','191':'Philadelphia','192':'Philadelphia',
  '193':'Philadelphia','194':'Philadelphia','195':'Philadelphia',
  '196':'Philadelphia',
  // Rhode Island
  '028':'Providence','029':'Providence',
  // South Carolina
  '290':'Columbia','291':'Columbia','292':'Columbia','293':'Spartanburg',
  '294':'Columbia','295':'Florence','296':'Greenville',
  '297':'Rock Hill','298':'Aiken','299':'Beaufort',
  // South Dakota
  '570':'Sioux Falls','571':'Watertown','572':'Aberdeen',
  '573':'Pierre','574':'Rapid City','575':'Rapid City',
  '576':'Mobridge','577':'Huron',
  // Tennessee
  '370':'Nashville','371':'Nashville','372':'Nashville','373':'Chattanooga',
  '374':'Chattanooga','375':'Memphis','376':'Johnson City',
  '377':'Knoxville','378':'Knoxville','379':'Knoxville',
  '380':'Memphis','381':'Memphis','382':'Jackson',
  '383':'Jackson','384':'Columbia','385':'Columbia',
  // Texas — full coverage
  '750':'Dallas','751':'Dallas','752':'Dallas','753':'Dallas',
  '754':'Greenville','755':'Texarkana','756':'Longview',
  '757':'Tyler','758':'Palestine','759':'Lufkin',
  '760':'Fort Worth','761':'Fort Worth','762':'Fort Worth',
  '763':'Waco','764':'Waco','765':'Waco',
  '766':'Waco','767':'Waco','768':'Abilene',
  '769':'Abilene','770':'Houston','771':'Houston',
  '772':'Houston','773':'Houston','774':'Houston',
  '775':'Galveston','776':'Beaumont','777':'Beaumont',
  '778':'Bryan','779':'Victoria','780':'San Antonio',
  '781':'San Antonio','782':'San Antonio','783':'San Antonio',
  '784':'Corpus Christi','785':'McAllen',
  '786':'Austin','787':'Austin','788':'Austin',
  '789':'Austin',
  '790':'Amarillo','791':'Amarillo','792':'Lubbock',
  '793':'Lubbock','794':'Lubbock',
  '795':'Midland','796':'Odessa','797':'Odessa',
  '798':'El Paso','799':'El Paso',
  // Utah
  '840':'Salt Lake City','841':'Salt Lake City','842':'Salt Lake City',
  '843':'Ogden','844':'Ogden','845':'Provo','846':'Provo','847':'Provo',
  // Vermont
  '050':'White River Junction','051':'Bellows Falls',
  '052':'Brattleboro','053':'Brattleboro','054':'Burlington',
  '055':'Burlington','056':'Burlington','057':'Burlington',
  '058':'Burlington','059':'Montpelier',
  // Virginia
  '200':'Arlington','201':'Arlington','220':'Arlington',
  '221':'Alexandria','222':'Arlington','223':'Alexandria',
  '224':'Fairfax','225':'Fairfax','226':'Fairfax',
  '227':'Manassas','228':'Fredericksburg','229':'Charlottesville',
  '230':'Richmond','231':'Richmond','232':'Richmond',
  '233':'Norfolk','234':'Norfolk','235':'Norfolk',
  '236':'Norfolk','237':'Virginia Beach','238':'Hampton',
  '239':'Hampton','240':'Roanoke','241':'Roanoke',
  '242':'Bristol','243':'Roanoke','244':'Roanoke',
  '245':'Staunton','246':'Bluefield',
  // Washington
  '980':'Seattle','981':'Seattle','982':'Seattle','983':'Tacoma',
  '984':'Tacoma','985':'Olympia','986':'Vancouver',
  '988':'Yakima','989':'Wenatchee','990':'Spokane',
  '991':'Spokane','992':'Spokane','993':'Spokane','994':'Pullman',
  // West Virginia
  '247':'Bluefield','248':'Lewisburg','249':'Beckley',
  '250':'Charleston','251':'Charleston','252':'Charleston',
  '253':'Charleston','254':'Charleston','255':'Huntington',
  '256':'Huntington','257':'Parkersburg','258':'Parkersburg',
  '259':'Clarksburg','260':'Clarksburg','261':'Martinsburg',
  '262':'Martinsburg','263':'Elkins','264':'Elkins',
  '265':'Morgantown','266':'Morgantown','267':'Wheeling',
  '268':'Wheeling',
  // Wisconsin
  '530':'Milwaukee','531':'Milwaukee','532':'Milwaukee',
  '534':'Racine','535':'Beloit','537':'Madison',
  '538':'Madison','539':'Janesville','540':'Green Bay',
  '541':'Green Bay','542':'Green Bay','543':'Green Bay',
  '544':'Wausau','545':'Wausau','546':'La Crosse',
  '547':'Eau Claire','548':'Superior','549':'Oshkosh',
  // Wyoming
  '820':'Cheyenne','821':'Cheyenne','822':'Cheyenne',
  '823':'Rawlins','824':'Rawlins','825':'Riverton',
  '826':'Casper','827':'Casper','828':'Casper',
  '829':'Casper','830':'Rock Springs','831':'Rock Springs',
};

class EventService {
  final EventRepository _repository;
  final TicketmasterService? _ticketmaster;

  EventService({
    required EventRepository repository,
    TicketmasterService? ticketmaster,
  })  : _repository = repository,
        _ticketmaster = ticketmaster;

  /// Merges curated/Firestore rows with live Ticketmaster listings and
  /// drops same-show duplicates. Placeholder Ticketmaster seed rows
  /// (Chihuahuas / Coliseum / Sun Bowl / symphony) are dropped once the
  /// API returns real dates for those venues.
  Future<List<Event>> _withLiveListings({
    required List<Event> local,
    String? city,
    String? state,
    double? lat,
    double? lng,
  }) async {
    final tm = _ticketmaster;
    if (tm == null || !tm.isConfigured) {
      return dedupeEvents(local);
    }
    final remote = await tm.search(
      city: city,
      stateCode: state,
      lat: lat,
      lng: lng,
    );
    var curated = local;
    if (remote.isNotEmpty) {
      curated = local
          .where((e) =>
              !(e.id.startsWith('evt_ep_') &&
                  e.source == EventSource.ticketmaster))
          .toList();
    }
    return dedupeEvents([...curated, ...remote]);
  }

  Future<Event?> getEventById(String id) async {
    final local = await _repository.getEventById(id);
    if (local != null) return local;
    return _ticketmaster?.getEventById(id);
  }

  Future<List<Event>> getUpcomingEvents({
    String? category,
    String? searchQuery,
    /// Preset shortcut: 'today' | 'tomorrow' | 'this_weekend' | 'this_week' | 'custom' | null
    String? datePreset,
    DateTime? dateFrom,
    DateTime? dateTo,
    /// Price tier: 'free' | 'under_20' | 'under_50' | null = any
    String? priceFilter,
    String? costType, // 'free' | 'paid' | null = any (legacy, prefer priceFilter)
    /// Time of day: 'morning' (6–12) | 'afternoon' (12–17) | 'evening' (17–21) | 'night' (21–6) | null
    String? timeOfDay,
    String? locationQuery, // filter sheet location
    String? areaQuery,    // zip code, city, or state from area search bar
    double searchRadius = 25.0, // miles; 100 = any distance
    Set<EventSource>? sources, // which platforms to include
    /// User's GPS coordinates for distance-based sorting and radius filtering.
    double? userLat,
    double? userLng,
    bool sortByDistance = false,
  }) async {
    List<Event> filtered;

    // ── Area search: curated local rows + live Ticketmaster for that city ──
    if (areaQuery != null && areaQuery.isNotEmpty) {
      final resolved = _resolveLocation(areaQuery);
      if (resolved != null) {
        filtered = await _repository.getEventsForLocation(
          city: resolved.city,
          state: resolved.state,
          zip: resolved.zip.isNotEmpty ? resolved.zip : areaQuery.trim(),
        );
        filtered = await _withLiveListings(
          local: filtered,
          city: resolved.city,
          state: resolved.state,
        );
      } else {
        // Unrecognised input — try Ticketmaster with the raw city string
        // instead of inventing "Live Music Night — City" listings.
        final defaults = await _repository.getUpcomingEvents();
        final aq = areaQuery.toLowerCase().trim();
        final matched = defaults.where((e) =>
            e.city.toLowerCase().contains(aq) ||
            e.state.toLowerCase().contains(aq) ||
            e.zipCode.contains(aq) ||
            e.address.toLowerCase().contains(aq) ||
            e.location.toLowerCase().contains(aq)).toList();
        filtered = await _withLiveListings(
          local: matched,
          city: areaQuery.trim(),
        );
      }
      filtered = filtered.where((e) => e.dateTime.isAfter(DateTime.now())).toList();
    } else {
      final events = await _repository.getUpcomingEvents();
      filtered = events.where((e) => e.dateTime.isAfter(DateTime.now())).toList();
      filtered = await _withLiveListings(
        local: filtered,
        lat: userLat ?? kElPasoLat,
        lng: userLng ?? kElPasoLng,
      );
      // Default city bias: El Paso metro when the user hasn't searched a
      // city and hasn't shared GPS yet. Nearby GPS still wins via the
      // haversine filter below.
      if (userLat == null && userLng == null) {
        final nearby = filtered.where((e) {
          if (e.city.toLowerCase() == kElPasoCity.toLowerCase()) return true;
          if (e.latitude == 0 && e.longitude == 0) return false;
          return _haversineDistanceMiles(
                kElPasoLat, kElPasoLng, e.latitude, e.longitude) <=
              40;
        }).toList();
        if (nearby.isNotEmpty) filtered = nearby;
      }
    }

    if (category != null && category != 'All') {
      filtered = filtered.where((e) => e.category == category).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((e) =>
          e.title.toLowerCase().contains(query) ||
          e.location.toLowerCase().contains(query) ||
          e.description.toLowerCase().contains(query) ||
          e.category.toLowerCase().contains(query) ||
          e.organizerName.toLowerCase().contains(query)).toList();
    }

    // ── Date preset filtering ──────────────────────────────────────────────────
    if (datePreset != null && datePreset != 'all' && datePreset != 'custom') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      switch (datePreset) {
        case 'today':
          final endOfToday = today.add(const Duration(days: 1));
          filtered = filtered.where((e) =>
              !e.dateTime.isBefore(today) && e.dateTime.isBefore(endOfToday)).toList();
          break;
        case 'tomorrow':
          final startOfTomorrow = today.add(const Duration(days: 1));
          final endOfTomorrow = today.add(const Duration(days: 2));
          filtered = filtered.where((e) =>
              !e.dateTime.isBefore(startOfTomorrow) &&
              e.dateTime.isBefore(endOfTomorrow)).toList();
          break;
        case 'this_weekend':
          // Saturday = weekday 6, Sunday = weekday 7
          final daysUntilSaturday = (6 - now.weekday) % 7;
          final saturday = today.add(Duration(days: daysUntilSaturday == 0 ? 0 : daysUntilSaturday));
          final monday = saturday.add(const Duration(days: 2));
          filtered = filtered.where((e) =>
              !e.dateTime.isBefore(saturday) && e.dateTime.isBefore(monday)).toList();
          break;
        case 'this_week':
          final endOfWeek = today.add(const Duration(days: 7));
          filtered = filtered.where((e) =>
              !e.dateTime.isBefore(today) && e.dateTime.isBefore(endOfWeek)).toList();
          break;
      }
    }

    // ── Custom date-range filtering ────────────────────────────────────────────
    if (datePreset == 'custom' || datePreset == null) {
      if (dateFrom != null) {
        filtered = filtered.where((e) => !e.dateTime.isBefore(dateFrom)).toList();
      }
      if (dateTo != null) {
        final endOfDay = DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59);
        filtered = filtered.where((e) => e.dateTime.isBefore(endOfDay)).toList();
      }
    }

    // ── Price tier filtering ───────────────────────────────────────────────────
    if (priceFilter != null && priceFilter != 'all') {
      switch (priceFilter) {
        case 'free':
          filtered = filtered.where((e) => e.isFree).toList();
          break;
        case 'under_20':
          filtered = filtered.where((e) => e.isFree || (e.cost != null && e.cost! < 20)).toList();
          break;
        case 'under_50':
          filtered = filtered.where((e) => e.isFree || (e.cost != null && e.cost! < 50)).toList();
          break;
      }
    } else if (costType == 'free') {
      filtered = filtered.where((e) => e.isFree).toList();
    } else if (costType == 'paid') {
      filtered = filtered.where((e) => !e.isFree).toList();
    }

    // ── Time of day filtering ──────────────────────────────────────────────────
    if (timeOfDay != null && timeOfDay != 'all') {
      filtered = filtered.where((e) {
        final hour = e.dateTime.hour;
        switch (timeOfDay) {
          case 'morning':   return hour >= 6 && hour < 12;
          case 'afternoon': return hour >= 12 && hour < 17;
          case 'evening':   return hour >= 17 && hour < 21;
          case 'night':     return hour >= 21 || hour < 6;
          default:          return true;
        }
      }).toList();
    }

    if (locationQuery != null && locationQuery.isNotEmpty) {
      final lq = locationQuery.toLowerCase();
      filtered = filtered.where((e) =>
          e.location.toLowerCase().contains(lq) ||
          e.address.toLowerCase().contains(lq) ||
          e.city.toLowerCase().contains(lq) ||
          e.state.toLowerCase().contains(lq)).toList();
    }

    if (sources != null && sources.isNotEmpty) {
      filtered = filtered.where((e) => sources.contains(e.source)).toList();
    }

    // ── Distance-based radius filter + sort ───────────────────────────────────
    // When the user shares their GPS location we filter to only events within
    // searchRadius miles (using real haversine math on event lat/lng) and then
    // sort by ascending distance so the closest events appear first.
    // Events with no coordinates (lat==0 && lng==0) are kept but sorted last.
    if (userLat != null && userLng != null) {
      // Radius filter — only drop if radius < 100 (100 = "any distance" sentinel)
      if (searchRadius < 100) {
        filtered = filtered.where((e) {
          if (e.latitude == 0 && e.longitude == 0) return true; // no coords → keep
          return _haversineDistanceMiles(userLat, userLng, e.latitude, e.longitude) <= searchRadius;
        }).toList();
      }

      if (sortByDistance) {
        filtered.sort((a, b) {
          final hasA = !(a.latitude == 0 && a.longitude == 0);
          final hasB = !(b.latitude == 0 && b.longitude == 0);
          if (!hasA && !hasB) return a.dateTime.compareTo(b.dateTime);
          if (!hasA) return 1;
          if (!hasB) return -1;
          final dA = _haversineDistanceMiles(userLat, userLng, a.latitude, a.longitude);
          final dB = _haversineDistanceMiles(userLat, userLng, b.latitude, b.longitude);
          return dA.compareTo(dB);
        });
        return filtered;
      }
    }

    filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return filtered;
  }

  Future<Event> toggleBookmark(Event event) async {
    await _repository.toggleBookmark(event.id);
    return event.copyWith(
      isBookmarked: !event.isBookmarked,
      bookmarkedCount: event.isBookmarked ? event.bookmarkedCount - 1 : event.bookmarkedCount + 1,
    );
  }

  Future<Event> toggleInterested(Event event) async {
    await _repository.toggleInterested(event.id);
    return event.copyWith(
      isInterested: !event.isInterested,
      interestedCount: event.isInterested ? event.interestedCount - 1 : event.interestedCount + 1,
    );
  }

  List<String> getCategories() {
    return ['All', 'Music', 'Food', 'Arts', 'Wellness', 'Social', 'Community', 'Markets', 'Dance', 'Technology', 'Sports', 'Fun & Games'];
  }
}

// ── Haversine formula — straight-line distance between two lat/lng points ────
double _haversineDistanceMiles(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusMiles = 3958.8;
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusMiles * c;
}

double _toRad(double deg) => deg * math.pi / 180;
