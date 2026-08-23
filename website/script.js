/**
 * Al-Mufradun — Interactive Scripts
 * Language Swapping, Dynamic Year, Smooth Scrolling, and Interactive Tasbih Widget
 */

document.addEventListener('DOMContentLoaded', () => {
    // ----------------------------------------------------
    // 1. Dynamic Footer Year
    // ----------------------------------------------------
    const footerYear = document.getElementById('footer-year');
    if (footerYear) {
        footerYear.textContent = new Date().getFullYear();
    }

    // ----------------------------------------------------
    // 2. Smooth Scrolling for Navigation Links
    // ----------------------------------------------------
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;

            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                targetElement.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // ----------------------------------------------------
    // 3. Interactive Dhikr (Tasbih) Widget
    // ----------------------------------------------------
    const tapBtn = document.getElementById('mock-tap-btn');
    const counterDisplay = document.getElementById('mock-counter');
    const resetBtn = document.getElementById('mock-reset-btn');
    let count = 0;

    if (tapBtn && counterDisplay && resetBtn) {
        // Tapping the Counter
        tapBtn.addEventListener('click', () => {
            count++;
            counterDisplay.textContent = count;
            
            // Add pulse micro-animation
            counterDisplay.classList.add('pulse');
            setTimeout(() => {
                counterDisplay.classList.remove('pulse');
            }, 150);

            // Change phrase or reset count dynamically on standard count milestones
            if (count === 33) {
                tapBtn.textContent = 'الحمد لله';
                tapBtn.style.backgroundColor = 'var(--secondary-color)';
                tapBtn.style.color = 'var(--primary-color)';
            } else if (count === 66) {
                tapBtn.textContent = 'الله أكبر';
                tapBtn.style.backgroundColor = 'var(--primary-light)';
                tapBtn.style.color = '#ffffff';
            } else if (count === 99) {
                tapBtn.textContent = 'لا إله إلا الله';
                tapBtn.style.backgroundColor = '#d4af37';
                tapBtn.style.color = 'var(--primary-color)';
            } else if (count === 100) {
                // Celebration effect & reset suggestion
                alert(document.documentElement.lang === 'ar' ? 'تقبل الله طاعتك! تم إكمال ١٠٠ تسبيحة.' : 'May Allah accept your worship! 100 praises completed.');
                resetDhikr();
            }
        });

        // Reset Counter
        resetBtn.addEventListener('click', (e) => {
            e.preventDefault();
            resetDhikr();
        });

        function resetDhikr() {
            count = 0;
            counterDisplay.textContent = '0';
            const lang = document.documentElement.lang;
            tapBtn.textContent = lang === 'ar' ? 'اضغط للتسبيح' : 'Tap to Praise';
            tapBtn.style.backgroundColor = 'var(--primary-color)';
            tapBtn.style.color = '#ffffff';
        }
    }

    // ----------------------------------------------------
    // 4. Privacy Policy Language Tabs
    // ----------------------------------------------------
    const tabButtons = document.querySelectorAll('.tab-btn');
    const policyContents = document.querySelectorAll('.policy-content');

    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            const targetId = button.getAttribute('data-target');

            // Deactivate all tabs and contents
            tabButtons.forEach(btn => btn.classList.remove('active'));
            policyContents.forEach(content => content.classList.remove('active'));

            // Activate target tab and content
            button.classList.add('active');
            const targetContent = document.getElementById(targetId);
            if (targetContent) {
                targetContent.classList.add('active');
            }
        });
    });

    // ----------------------------------------------------
    // 5. Global Language Switcher (EN <=> AR Translations)
    // ----------------------------------------------------
    const langToggleBtn = document.getElementById('lang-toggle-btn');
    
    // Page Content Dictionary
    const translations = {
        en: {
            langButton: 'العربية',
            navFeatures: 'Features',
            navPrivacy: 'Privacy Policy',
            navDownload: 'Download',
            heroBadge: 'Islamic Companion App',
            heroTitle: 'Al-Mufradun',
            heroTagline: 'Your daily companion for Azkar, Prayer Times, and the Holy Quran. Designed with ultimate privacy, simplicity, and serenity.',
            heroDownload: 'Download on Google Play',
            heroPrivacy: 'Read Privacy Policy',
            widgetNext: 'Next Prayer',
            widgetRemaining: '1h 12m remaining',
            widgetLoc: 'Riyadh, KSA',
            widgetTap: 'Tap to Praise',
            widgetReset: 'Reset Counter',
            featuresTitle: 'Core Features',
            featuresSubtitle: 'Everything you need to maintain your daily worship, consolidated in a single, lightweight application.',
            f1Title: 'Daily Azkar & Supplications',
            f1Desc: 'Access authenticated morning, evening, and sleep supplications, with automatic progress tracking per category.',
            f2Title: 'Accurate Prayer Times',
            f2Desc: 'Offline calculation using coordinates with standard Muslim world calculation methods, featuring countdowns and Iqamah markers.',
            f3Title: 'Qibla Compass',
            f3Desc: 'An easy-to-use, localized compass with Arabic cardinal indicators (ش/ج/شر/غ) that guides you straight to the Kaaba.',
            f4Title: 'The Holy Quran',
            f4Desc: 'A full 604-page Mushaf PageView utilizing the beautiful Uthmanic font, featuring range selection and customizable verse actions.',
            downTitle: 'Start Your Daily Spiritual Journey',
            downDesc: 'Download Al-Mufradun now and access your daily Azkar, offline prayer calculations, and Quran in a modern and clean design.',
            downBtn: 'Download on Google Play',
            footerNote: 'Designed and built with absolute privacy in mind.'
        },
        ar: {
            langButton: 'English',
            navFeatures: 'المميزات',
            navPrivacy: 'سياسة الخصوصية',
            navDownload: 'تحميل التطبيق',
            heroBadge: 'تطبيق العبادات الإسلامية المتكامل',
            heroTitle: 'المفردون',
            heroTagline: 'رفيقك اليومي للأذكار ومواقيت الصلاة والقرآن الكريم. مصمم بخصوصية تامة، وسهولة تامة، وبساطة وهدوء.',
            heroDownload: 'تحميل من جوجل بلاي',
            heroPrivacy: 'سياسة الخصوصية',
            widgetNext: 'الصلاة القادمة',
            widgetRemaining: 'متبقي 01:12:45',
            widgetLoc: 'الرياض، السعودية',
            widgetTap: 'اضغط للتسبيح',
            widgetReset: 'إعادة تعيين',
            featuresTitle: 'مميزات التطبيق الرئيسية',
            featuresSubtitle: 'كل ما تحتاجه للحفاظ على أورادك وعباداتك اليومية، مجموع في تطبيق واحد خفيف الحجم.',
            f1Title: 'الأذكار والأوراد اليومية',
            f1Desc: 'تصفح أذكار الصباح والمساء والنوم والاستيقاظ الموثقة، مع مؤشر تقدم لكل قسم.',
            f2Title: 'مواقيت الصلاة الدقيقة',
            f2Desc: 'حساب دقيق لأوقات الصلاة دون اتصال بالإنترنت مبني على موقعك وبطرق الحساب الرسمية، مع عد تنازلي ووقت الإقامة.',
            f3Title: 'بوصلة القبلة باللغة العربية',
            f3Desc: 'بوصلة سهلة الاستخدام ومبسطة بالكامل بالاتجاهات العربية (ش/ج/شر/غ) لإرشادك نحو الكعبة المشرفة.',
            f4Title: 'القرآن الكريم بالرسم العثماني',
            f4Desc: 'مصحف كامل (٦٠٤ صفحة) بخط الرسم العثماني العتيق، مع تحديد نطاقات الآيات ومجموعة من الإجراءات السريعة على الآية.',
            downTitle: 'ابدأ رحلتك الإيمانية اليومية',
            downDesc: 'حمّل تطبيق المفردون الآن وتصفح أذكارك وصلاواتك وقرآنك بتصميم عصري وأنيق خالٍ من الإعلانات تماماً.',
            downBtn: 'تحميل من متجر جوجل بلاي',
            footerNote: 'تم التطوير والتصميم مع التركيز الكامل على الخصوصية المطلقة للمستخدم.'
        }
    };

    if (langToggleBtn) {
        langToggleBtn.addEventListener('click', () => {
            const currentLang = document.documentElement.lang;
            const newLang = currentLang === 'en' ? 'ar' : 'en';
            
            // Set Document attributes
            document.documentElement.lang = newLang;
            document.documentElement.dir = newLang === 'ar' ? 'rtl' : 'ltr';

            // Apply translations to individual elements
            langToggleBtn.textContent = translations[newLang].langButton;
            
            // Navigation Links
            const navLinks = document.querySelectorAll('.nav-link');
            if (navLinks.length >= 2) {
                navLinks[0].textContent = translations[newLang].navFeatures;
                navLinks[1].textContent = translations[newLang].navPrivacy;
            }
            
            const navDownload = document.querySelector('.navbar .btn-secondary');
            if (navDownload) navDownload.textContent = translations[newLang].navDownload;

            // Hero Section
            const heroBadge = document.querySelector('.hero-content .badge');
            if (heroBadge) heroBadge.textContent = translations[newLang].heroBadge;

            const heroTitle = document.querySelector('.hero-title');
            if (heroTitle) {
                if (newLang === 'en') {
                    heroTitle.innerHTML = 'Al-Mufradun <span class="arabic-display">المفردون</span>';
                } else {
                    heroTitle.innerHTML = 'المفردون <span class="arabic-display" style="font-size: 2.2rem; font-family: var(--font-ui); display: inline-block; margin-right: 12px; color: var(--text-muted);">Al-Mufradun</span>';
                }
            }

            const heroTagline = document.querySelector('.hero-tagline');
            if (heroTagline) heroTagline.textContent = translations[newLang].heroTagline;

            const heroDownloadBtn = document.querySelector('.hero-actions .btn-primary');
            if (heroDownloadBtn) {
                heroDownloadBtn.innerHTML = `
                    <svg class="btn-icon" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M5,20H19V18H5M19,9H15V3H9V9H5L12,16L19,9Z" />
                    </svg>
                    ${translations[newLang].heroDownload}
                `;
            }

            const heroPrivacyBtn = document.querySelector('.hero-actions .btn-outline');
            if (heroPrivacyBtn) heroPrivacyBtn.textContent = translations[newLang].heroPrivacy;

            // Mockup Widget
            const widgetNext = document.querySelector('.prayer-widget .widget-title');
            if (widgetNext) widgetNext.textContent = translations[newLang].widgetNext;

            const widgetTime = document.querySelector('.prayer-widget .widget-time');
            if (widgetTime) {
                widgetTime.textContent = newLang === 'en' ? 'Asr - 03:42 PM' : 'العصر - 03:42 م';
            }

            const widgetRemaining = document.querySelector('.prayer-widget .widget-footer span:first-child');
            if (widgetRemaining) {
                widgetRemaining.textContent = newLang === 'en' ? '01:12:45 remaining' : 'متبقي 01:12:45';
            }

            const widgetLoc = document.querySelector('.prayer-widget .widget-footer span:last-child');
            if (widgetLoc) widgetLoc.textContent = translations[newLang].widgetLoc;

            const widgetDhikrTitle = document.querySelector('.dhikr-widget .dhikr-title');
            if (widgetDhikrTitle) {
                widgetDhikrTitle.textContent = newLang === 'en' ? 'Subhan Allah wa bihamdih' : 'سبحان الله وبحمده';
            }

            const widgetTapBtn = document.getElementById('mock-tap-btn');
            if (widgetTapBtn) {
                // If counter is active, adjust button text accordingly
                if (count === 0) {
                    widgetTapBtn.textContent = translations[newLang].widgetTap;
                } else if (count >= 33 && count < 66) {
                    widgetTapBtn.textContent = newLang === 'en' ? 'Alhamdulillah' : 'الحمد لله';
                } else if (count >= 66 && count < 99) {
                    widgetTapBtn.textContent = newLang === 'en' ? 'Allahu Akbar' : 'الله أكبر';
                } else if (count >= 99 && count < 100) {
                    widgetTapBtn.textContent = newLang === 'en' ? 'La ilaha illa Allah' : 'لا إله إلا الله';
                } else {
                    widgetTapBtn.textContent = translations[newLang].widgetTap;
                }
            }

            const widgetReset = document.getElementById('mock-reset-btn');
            if (widgetReset) widgetReset.textContent = translations[newLang].widgetReset;

            // Features Header
            const fHeaderTitle = document.querySelector('.features-section .section-title');
            if (fHeaderTitle) fHeaderTitle.textContent = translations[newLang].featuresTitle;

            const fHeaderSub = document.querySelector('.features-section .section-subtitle');
            if (fHeaderSub) fHeaderSub.textContent = translations[newLang].featuresSubtitle;

            // Feature Cards
            const fCards = document.querySelectorAll('.feature-card');
            if (fCards.length >= 4) {
                // Card 1
                fCards[0].querySelector('h3').textContent = translations[newLang].f1Title;
                fCards[0].querySelector('p').textContent = translations[newLang].f1Desc;
                // Card 2
                fCards[1].querySelector('h3').textContent = translations[newLang].f2Title;
                fCards[1].querySelector('p').textContent = translations[newLang].f2Desc;
                // Card 3
                fCards[2].querySelector('h3').textContent = translations[newLang].f3Title;
                fCards[2].querySelector('p').textContent = translations[newLang].f3Desc;
                // Card 4
                fCards[3].querySelector('h3').textContent = translations[newLang].f4Title;
                fCards[3].querySelector('p').textContent = translations[newLang].f4Desc;
            }

            // Sync Privacy Tab
            const policyEnBtn = document.querySelector('.tab-btn[data-target="policy-en"]');
            const policyArBtn = document.querySelector('.tab-btn[data-target="policy-ar"]');
            if (newLang === 'en' && policyEnBtn) {
                policyEnBtn.click();
            } else if (newLang === 'ar' && policyArBtn) {
                policyArBtn.click();
            }

            // Download Banner
            const downloadSection = document.getElementById('download');
            if (downloadSection) {
                downloadSection.querySelector('h2').textContent = translations[newLang].downTitle;
                downloadSection.querySelector('p').textContent = translations[newLang].downDesc;
                
                const downBtn = downloadSection.querySelector('.btn-secondary');
                if (downBtn) {
                    downBtn.innerHTML = `
                        <svg class="btn-icon" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M5,20H19V18H5M19,9H15V3H9V9H5L12,16L19,9Z" />
                        </svg>
                        ${translations[newLang].downBtn}
                    `;
                }
            }

            // Footer
            const footerNote = document.querySelector('.footer-note');
            if (footerNote) footerNote.textContent = translations[newLang].footerNote;
        });
    }
});
