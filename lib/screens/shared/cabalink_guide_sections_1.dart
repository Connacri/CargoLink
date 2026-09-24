// Sections 1 à 15 du guide CabaLink (transcription fidèle, FR + AR).
import 'cabalink_guide_content.dart';

final List<CabalinkGuideSection> cabalinkGuideSectionsPart1 = [
  sec(
    1,
    "Qu’est-ce que CabaLink ?",
    "ما هي CabaLink؟",
    [
      par(
        "CabaLink est une plateforme spécialisée dans le transport international via des voyageurs, micro-importateurs et transporteurs.",
      ),
      par("Elle met en relation :"),
      bul([
        "Le client : la personne qui souhaite envoyer ou recevoir des marchandises.",
        "Le transporteur : la personne qui transporte physiquement la marchandise. Il peut être :",
      ]),
      bul([
        "Un voyageur.",
        "Un micro-importateur.",
        "Un transporteur professionnel.",
      ]),
      bul([
        "L’ambassadeur : la personne qui apporte de nouveaux transporteurs à CabaLink grâce à son code de parrainage.",
        "CabaLink : la plateforme qui organise et encadre le processus, avec vérification, documentation, suivi et évaluation.",
        "Le partenaire : une entreprise ou une entité pouvant établir un partenariat avec CabaLink, sans être un rôle obligatoire dans une opération de transport.",
      ]),
      quo(
        "Le bureau de livraison ou de transport n’est pas un rôle principal de CabaLink.\nUne entreprise de transport ou de logistique peut contacter CabaLink et devenir partenaire, mais l’opération principale reste organisée entre le client et le transporteur via la plateforme.",
      ),
    ],
    [
      par("CabaLink هي منصة متخصصة في النقل الدولي عبر شبكة من الناقلين، تربط بين:"),
      bul([
        "العميل: الشخص الذي يريد إرسال أو استلام بضائع.",
        "الناقل: الشخص الذي ينقل البضاعة فعليًا، ويمكن أن يكون:",
      ]),
      bul([
        "مسافرًا.",
        "مستوردًا مصغرًا.",
        "ناقلًا محترفًا.",
      ]),
      bul([
        "السفير: الشخص الذي يجلب ناقلين جددًا إلى المنصة عن طريق الإحالة.",
        "CabaLink: المنصة التي تنظم العملية وتوفر التوثيق والتتبع والتحقق وإدارة العملية.",
        "الشريك: شركة أو جهة أو شخص يمكن أن يدخل في شراكة مع CabaLink، لكنه ليس دورًا أساسيًا داخل عملية النقل.",
      ]),
      quo(
        "مكتب الشحن ليس دورًا أساسيًا في نموذج CabaLink.\nيمكن لشركة شحن أو شركة لوجستية التواصل مع CabaLink وإقامة شراكة، لكن المعاملة الأساسية تتم بين العميل والناقل عبر المنصة.",
      ),
    ],
  ),
  sec(
    2,
    "L’idée principale",
    "الفكرة الأساسية",
    [
      par(
        "L’idée de CabaLink est de transformer le poids disponible lors d’un voyage en opportunité de revenu.",
      ),
      par(
        "Un voyageur peut avoir payé à l’avance une certaine quantité de bagages dans son billet d’avion sans utiliser la totalité de son poids autorisé.",
      ),
      par("Au lieu de laisser ce poids inutilisé, il peut publier :"),
      bul([
        "sa date de voyage ;",
        "sa destination ;",
        "son poids disponible ;",
        "son prix par kilogramme ;",
        "les informations nécessaires concernant son voyage.",
      ]),
      par(
        "Les clients peuvent ensuite rechercher les voyages correspondant à leurs besoins.",
      ),
      par(
        "Le transporteur peut également, lorsque la compagnie aérienne et la réglementation le permettent, acheter du poids supplémentaire auprès de la compagnie aérienne afin de transporter davantage de marchandises.",
      ),
      par("Le voyage peut ainsi devenir une source de revenu supplémentaire."),
    ],
    [
      par("الفكرة هي تحويل الوزن المتاح في رحلة السفر إلى فرصة لتحقيق دخل."),
      par("المسافر قد يمتلك وزنًا مدفوعًا مسبقًا ضمن تذكرة سفره لكنه لا يستعمله بالكامل."),
      par("بدل أن يذهب هذا الوزن دون استفادة، يستطيع الناقل نشر:"),
      bul([
        "تاريخ السفر.",
        "وجهة السفر.",
        "الوزن المتاح.",
        "السعر الذي يحدده لكل كيلوغرام.",
        "معلومات الرحلة المطلوبة.",
      ]),
      par("ثم يستطيع العملاء البحث عن الرحلات المناسبة لهم والتواصل مع الناقل عبر CabaLink."),
      par(
        "كما يمكن للناقل، وفق شروط شركة الطيران والقوانين المعمول بها، شراء وزن إضافي من شركة الطيران واستغلاله لنقل بضائع أخرى.",
      ),
      par("وبذلك يمكن أن تتحول عملية السفر من مجرد تكلفة إلى فرصة لتحقيق دخل إضافي."),
    ],
  ),
  sec(
    3,
    "Qui peut être transporteur ?",
    "من يمكنه أن يكون ناقلًا؟",
    [
      par(
        "Le terme transporteur est le terme général utilisé par CabaLink pour désigner toute personne qui transporte physiquement une marchandise.",
      ),
      par("Il peut s’agir de :"),
      bul([
        "A. Voyageur — Une personne qui voyage d’un pays à un autre et dispose d’un poids disponible dans ses bagages. Elle peut publier son voyage et proposer une partie de son poids disponible.",
        "B. Micro-importateur — Une personne qui importe de petites quantités de marchandises et qui peut également transporter les commandes d’autres clients. Selon l’accord conclu, il peut également prendre en charge certaines démarches douanières.",
        "C. Transporteur professionnel — Une personne qui fait du transport via les voyages de manière régulière ou professionnelle et qui peut organiser plusieurs opérations, dans le respect de la réglementation et des conditions des compagnies aériennes.",
      ]),
    ],
    [
      par("مصطلح الناقل هو المصطلح الموحد في CabaLink لكل شخص يقوم بنقل البضاعة."),
      par("وينقسم إلى:"),
      bul([
        "أ. المسافر — شخص يسافر من دولة إلى دولة أخرى ولديه وزن متاح في أمتعته. يمكنه نشر رحلته واستغلال الوزن المتاح لنقل بضائع العملاء.",
        "ب. المستورد المصغر — شخص يقوم باستيراد كميات صغيرة من السلع ويمكنه استغلال رحلاته أو قدرته على نقل بضائع الآخرين. ويمكنه، عند الاتفاق المسبق، التعامل مع الإجراءات الجمركية ضمن السعر المتفق عليه.",
        "ج. الناقل المحترف — شخص يجعل نقل البضائع عبر الرحلات نشاطًا منتظمًا أو مهنيًا، ويمكنه تنظيم رحلات متعددة واستغلال أوزان أكبر، وفق القوانين وشروط شركات الطيران.",
      ]),
    ],
  ),
  sec(
    4,
    "Le poids déjà payé dans le billet",
    "الوزن المدفوع مسبقًا",
    [
      par(
        "L’une des idées fondamentales de CabaLink est qu’un voyageur peut avoir déjà payé une capacité de bagages dans son billet d’avion.",
      ),
      par(
        "Par exemple, s’il dispose de 60 kg autorisés et n’en utilise que 20 kg, une partie de cette capacité reste inutilisée.",
      ),
      par(
        "CabaLink permet au voyageur d’exploiter cette capacité disponible afin de générer un revenu supplémentaire.",
      ),
      par(
        "Le transporteur peut également acheter du poids supplémentaire auprès de la compagnie aérienne lorsque cette possibilité est autorisée.",
      ),
    ],
    [
      par("من أهم أفكار CabaLink أن المسافر قد يكون قد دفع ثمن وزن أمتعته أصلًا ضمن تذكرة السفر."),
      par("إذا كان لديه مثلًا 60 كغ مسموحًا بها، واستعمل 20 كغ فقط، فإن جزءًا من الوزن المدفوع لا يزال غير مستغل."),
      par("CabaLink تسمح له باستغلال الوزن المتاح بطريقة منظمة، بدل تركه دون فائدة."),
      par("كما يمكنه شراء وزن إضافي من شركة الطيران، إذا كانت شركة الطيران تسمح بذلك، ثم استغلاله لنقل بضائع إضافية."),
    ],
  ),
  sec(
    5,
    "Création du compte",
    "إنشاء حساب",
    [
      par("L’utilisateur s’inscrit sur CabaLink selon son rôle, notamment :"),
      bul([
        "Client.",
        "Transporteur.",
      ]),
      par("Le transporteur peut ensuite créer son profil et publier ses voyages."),
      par("Deux niveaux principaux de compte sont prévus :"),
      bul([
        "Compte entièrement vérifié — L’identité est vérifiée à l’aide des documents nécessaires, par exemple un passeport et une photo, conformément aux procédures de CabaLink.",
        "Compte non vérifié — L’utilisateur peut également disposer d’un compte non entièrement vérifié. Cette information est visible afin que le client puisse en tenir compte lors du choix d’un transporteur.",
      ]),
    ],
    [
      par("يسجل المستخدم في CabaLink وفق صفته، مثل:"),
      bul([
        "عميل.",
        "ناقل.",
      ]),
      par("ويستطيع الناقل إنشاء ملف خاص به ونشر رحلاته."),
      par("يوجد مستويان أساسيان للحساب:"),
      bul([
        "حساب موثق بالكامل — يتم التحقق من الهوية باستخدام الوثائق المطلوبة، مثل جواز السفر والصورة، وفق إجراءات CabaLink.",
        "حساب غير موثق — يمكن أن يكون الحساب غير موثق بالكامل، ويظهر ذلك للعميل حتى يستطيع أخذ حالة التحقق بعين الاعتبار عند اختيار الناقل.",
      ]),
    ],
  ),
  sec(
    6,
    "Protection des documents d’identité",
    "حماية وثائق الهوية",
    [
      par("Les documents utilisés pour la vérification :"),
      bul([
        "ne sont pas publiés publiquement ;",
        "ne sont pas accessibles librement aux autres utilisateurs ;",
        "sont traités dans le cadre des procédures de sécurité et de confidentialité de la plateforme ;",
        "servent à vérifier l’identité du titulaire du compte.",
      ]),
      par("L’objectif est de combiner confiance et protection de la vie privée."),
    ],
    [
      par("وثائق الهوية المستخدمة في التحقق:"),
      bul([
        "لا يتم نشرها للعامة.",
        "لا تظهر للعملاء كوثائق مفتوحة.",
        "يتم التعامل معها وفق إجراءات حماية وخصوصية المنصة.",
        "تستخدم للتحقق من هوية صاحب الحساب.",
      ]),
      par("الهدف هو تحقيق التوازن بين الثقة والخصوصية."),
    ],
  ),
  sec(
    7,
    "Lutte contre les faux comptes",
    "مكافحة الحسابات الوهمية",
    [
      par("CabaLink ne se limite pas à la simple création d’un compte."),
      par("Les comptes, documents et informations peuvent être vérifiés afin de réduire les risques liés :"),
      bul([
        "aux fausses identités ;",
        "aux faux documents ;",
        "aux comptes frauduleux ;",
        "aux comptes multiples ou suspects.",
      ]),
      par(
        "Les documents et informations peuvent être examinés individuellement par des spécialistes afin de renforcer la fiabilité du système.",
      ),
      par("Les faux comptes ou comptes non conformes ne doivent pas pouvoir effectuer de transactions."),
    ],
    [
      par("CabaLink لا تعتمد فقط على إنشاء الحساب."),
      par(
        "يتم فحص الحسابات والوثائق والصور عند الحاجة، مع مراجعة المعلومات والوثائق بشكل فعلي من طرف المختصين لتقليل الحسابات الوهمية أو الهويات المزيفة.",
      ),
      par("الحسابات المزيفة أو المخالفة لا يسمح لها بإجراء معاملات على المنصة."),
    ],
  ),
  sec(
    8,
    "Publication d’un voyage",
    "نشر الرحلة",
    [
      par("Le transporteur peut publier son voyage en indiquant notamment :"),
      bul([
        "point de départ ;",
        "destination ;",
        "date du voyage ;",
        "poids disponible ;",
        "prix par kilogramme ;",
        "statut de vérification ;",
        "informations nécessaires à l’opération.",
      ]),
      par(
        "Une fois publié, le voyage devient visible aux clients recherchant une solution correspondant à leur destination et à leur date.",
      ),
    ],
    [
      par("يقوم الناقل بإضافة رحلته، وتتضمن المعلومات الأساسية مثل:"),
      bul([
        "نقطة الانطلاق.",
        "الوجهة.",
        "تاريخ السفر.",
        "الوزن المتاح.",
        "السعر لكل كيلوغرام.",
        "حالة التحقق من الحساب.",
        "المعلومات اللازمة للعملية.",
      ]),
      par("بعد نشر الرحلة تصبح متاحة للعملاء الذين يبحثون عن نقل بضائع في نفس الاتجاه والتاريخ."),
    ],
  ),
  sec(
    9,
    "Partage du voyage sur les réseaux sociaux",
    "مشاركة الرحلة على مواقع التواصل",
    [
      par(
        "Une fonction importante de CabaLink permet au transporteur de partager directement son voyage depuis l’application.",
      ),
      par("Il n’a donc pas besoin de réécrire manuellement la même annonce sur chaque réseau social."),
      par(
        "Il crée son voyage une seule fois dans CabaLink, puis peut le partager sur différentes plateformes sociales.",
      ),
    ],
    [
      par("من أهم وظائف CabaLink أن الناقل لا يحتاج إلى إعادة كتابة إعلان الرحلة في كل مرة."),
      par("يمكنه إنشاء الرحلة داخل التطبيق ثم مشاركة الرحلة مباشرة من التطبيق عبر شبكات التواصل الاجتماعي."),
      par("وبذلك يمكنه نشر نفس الرحلة على عدة منصات، مع الحفاظ على المعلومات الأساسية الموجودة في CabaLink."),
    ],
  ),
  sec(
    10,
    "Recherche du client",
    "بحث العميل عن الرحلة",
    [
      par("Le client peut rechercher les voyages selon plusieurs critères :"),
      bul([
        "destination ;",
        "date de voyage ;",
        "poids disponible ;",
        "prix par kilogramme ;",
        "statut de vérification ;",
        "informations sur le transporteur.",
      ]),
      par("Il peut ensuite sélectionner le voyage qui correspond à ses besoins."),
    ],
    [
      par("يستطيع العميل البحث عن الرحلات حسب عدة معايير، مثل:"),
      bul([
        "الوجهة.",
        "تاريخ السفر.",
        "الوزن المطلوب.",
        "السعر لكل كيلوغرام.",
        "حالة التحقق.",
        "معلومات الناقل.",
      ]),
      par("ثم يختار الرحلة المناسبة له ويتواصل مع الناقل من خلال المنصة."),
    ],
  ),
  sec(
    11,
    "Négociation et accord",
    "التفاوض والاتفاق",
    [
      par(
        "Le client et le transporteur peuvent échanger sur les détails de l’opération et convenir des conditions applicables.",
      ),
      par(
        "Les informations importantes et les accords doivent être documentés dans l’opération afin de réduire les risques de litige.",
      ),
    ],
    [
      par("يمكن للعميل والناقل مناقشة تفاصيل العملية والاتفاق على الشروط المناسبة."),
      par("ويجب أن تكون المعلومات والاتفاقات المهمة موثقة داخل العملية لتقليل الخلافات لاحقًا."),
    ],
  ),
  sec(
    12,
    "Point de collecte",
    "نقطة التجميع",
    [
      par("Un point de collecte est défini à l’avance."),
      par("Le client remet ou fait parvenir la marchandise au point enregistré selon les conditions convenues."),
      par("L’envoi d’une demande ne signifie pas automatiquement que le poids est réservé."),
    ],
    [
      par("يتم الاتفاق مسبقًا على نقطة استلام أو تجميع البضاعة."),
      par("يقوم العميل بإرسال البضاعة إلى النقطة المسجلة والمتفق عليها وفق شروط العملية."),
      par("عند وصول البضاعة إلى الناقل، لا يصبح الوزن محجوزًا لمجرد إرسال طلب."),
    ],
  ),
  sec(
    13,
    "Quand le poids est-il réellement réservé ?",
    "متى يتم حجز الوزن؟",
    [
      par("Le poids est réservé lorsque le transporteur reçoit la marchandise, l’inspecte et l’accepte."),
      par("Ainsi :"),
      frm([
        "Demande de transport ≠ réservation du poids",
        "Réception + inspection + acceptation = réservation du poids",
      ]),
      par("Il s’agit d’une règle fondamentale du fonctionnement de CabaLink."),
    ],
    [
      par("يتم حجز الوزن فعليًا عندما يستلم الناقل البضاعة ويقوم بفحصها ويوافق عليها."),
      par("أي أن:"),
      frm([
        "طلب النقل ≠ حجز الوزن",
        "استلام البضاعة + فحصها + قبولها = حجز الوزن",
      ]),
      par("وهذه نقطة أساسية في نظام CabaLink."),
    ],
  ),
  sec(
    14,
    "Inspection de la marchandise",
    "فحص البضاعة قبل قبولها",
    [
      par("Avant d’accepter une marchandise, le transporteur doit la contrôler."),
      par("Il doit vérifier qu’elle ne contient pas de produits :"),
      bul([
        "interdits ;",
        "réglementés ;",
        "illégaux ;",
        "incompatibles avec les conditions de transport ;",
        "interdits par la compagnie aérienne.",
      ]),
      par(
        "CabaLink prévoit une liste des produits interdits et réglementés, consultable par le client avant l’achat ou l’envoi.",
      ),
      par("Cette liste doit pouvoir être mise à jour lorsque les lois ou restrictions évoluent."),
    ],
    [
      par("على الناقل فحص البضاعة قبل قبولها."),
      par("ويجب التأكد من أنها لا تحتوي على مواد:"),
      bul([
        "ممنوعة.",
        "مقيدة.",
        "مخالفة للقوانين.",
        "مخالفة لشروط شركة الطيران أو النقل.",
      ]),
      par("تحتوي CabaLink على قائمة للمنتجات الممنوعة والمقيدة يمكن للعميل الاطلاع عليها قبل شراء المنتج أو إرساله."),
      par("ويجب تحديث القائمة عند تغير القوانين أو القيود ذات الصلة."),
    ],
  ),
  sec(
    15,
    "Marchandise non conforme",
    "ماذا يحدث إذا كانت البضاعة غير مطابقة؟",
    [
      par("Le transporteur peut refuser la marchandise avant son acceptation si elle :"),
      bul([
        "figure sur la liste des produits interdits ou réglementés ;",
        "ne correspond pas aux informations déclarées ;",
        "présente une différence importante par rapport à l’accord ;",
        "ne respecte pas les conditions de transport.",
      ]),
      par("Cela permet d’éviter l’introduction de marchandises non conformes dans le processus."),
    ],
    [
      par("يحق للناقل رفض البضاعة قبل قبولها إذا وجد أنها:"),
      bul([
        "مخالفة للقائمة.",
        "غير مطابقة للمعلومات المقدمة.",
        "تحتوي على مواد ممنوعة أو مقيدة.",
        "تختلف بشكل جوهري عن الاتفاق.",
      ]),
      par("وهذا يمنع دخول البضائع غير المقبولة إلى عملية النقل."),
    ],
  ),
];