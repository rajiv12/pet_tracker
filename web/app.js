// ── Data Layer ──
const PETS_KEY = 'pet_tracker_pets';
const DUTIES_KEY = 'pet_tracker_duties';

const PetTypes = {
    dog: { label: 'Dog', emoji: '🐕', categories: ['feeding','walking','grooming','vetvisit','medication','training','other'] },
    cat: { label: 'Cat', emoji: '🐈', categories: ['feeding','litterbox','grooming','vetvisit','medication','playtime','other'] }
};

const Categories = {
    feeding:    { label: 'Feeding',    icon: '🍽️', cssClass: 'cat-bg-feeding' },
    walking:    { label: 'Walking',    icon: '🚶', cssClass: 'cat-bg-walking' },
    litterbox:  { label: 'Litter Box', icon: '🪣', cssClass: 'cat-bg-litterbox' },
    grooming:   { label: 'Grooming',   icon: '✂️', cssClass: 'cat-bg-grooming' },
    vetvisit:   { label: 'Vet Visit',  icon: '🏥', cssClass: 'cat-bg-vetvisit' },
    medication: { label: 'Medication', icon: '💊', cssClass: 'cat-bg-medication' },
    training:   { label: 'Training',   icon: '⭐', cssClass: 'cat-bg-training' },
    playtime:   { label: 'Playtime',   icon: '🎮', cssClass: 'cat-bg-playtime' },
    other:      { label: 'Other',      icon: '📋', cssClass: 'cat-bg-other' }
};

const Recurrences = [
    { value: 'daily', label: 'Daily' },
    { value: 'everyother', label: 'Every Other Day' },
    { value: 'weekly', label: 'Weekly' },
    { value: 'biweekly', label: 'Biweekly' },
    { value: 'monthly', label: 'Monthly' },
    { value: 'yearly', label: 'Yearly' }
];

function loadPets() {
    try { return JSON.parse(localStorage.getItem(PETS_KEY)) || []; }
    catch { return []; }
}
function savePets(pets) { localStorage.setItem(PETS_KEY, JSON.stringify(pets)); }

function loadDuties() {
    try { return JSON.parse(localStorage.getItem(DUTIES_KEY)) || []; }
    catch { return []; }
}
function saveDuties(duties) { localStorage.setItem(DUTIES_KEY, JSON.stringify(duties)); }

function uuid() {
    return 'xxxx-xxxx-xxxx'.replace(/x/g, () => Math.floor(Math.random() * 16).toString(16));
}

function isToday(dateStr) {
    const d = new Date(dateStr);
    const now = new Date();
    return d.toDateString() === now.toDateString();
}

function isOverdue(dateStr, completed) {
    return !completed && new Date(dateStr) < new Date();
}

function isUpcoming(dateStr, completed) {
    if (completed) return false;
    const d = new Date(dateStr);
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0,0,0,0);
    const weekOut = new Date(now);
    weekOut.setDate(weekOut.getDate() + 7);
    return d >= tomorrow && d <= weekOut;
}

function petAge(dob) {
    if (!dob) return null;
    const d = new Date(dob);
    const now = new Date();
    let years = now.getFullYear() - d.getFullYear();
    let months = now.getMonth() - d.getMonth();
    if (months < 0) { years--; months += 12; }
    if (years > 0) return `${years} year${years === 1 ? '' : 's'}`;
    return `${months} month${months === 1 ? '' : 's'}`;
}

function formatDateTime(dateStr) {
    const d = new Date(dateStr);
    const month = d.toLocaleDateString('en-US', { month: 'short' });
    const day = d.getDate();
    const time = d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
    return `${month} ${day}, ${time}`;
}

function formatTime(dateStr) {
    return new Date(dateStr).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
}

function nextRecurrence(dateStr, interval) {
    const d = new Date(dateStr);
    switch (interval) {
        case 'daily': d.setDate(d.getDate() + 1); break;
        case 'everyother': d.setDate(d.getDate() + 2); break;
        case 'weekly': d.setDate(d.getDate() + 7); break;
        case 'biweekly': d.setDate(d.getDate() + 14); break;
        case 'monthly': d.setMonth(d.getMonth() + 1); break;
        case 'yearly': d.setFullYear(d.getFullYear() + 1); break;
    }
    return d.toISOString();
}

// ── HTML escape for user-provided strings ──
function esc(str) {
    if (!str) return '';
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// ── State ──
let pets = loadPets();
let duties = loadDuties();
let currentView = 'dashboard';
let currentPetId = null;
let filterCompleted = false;

// ── DOM Refs ──
const $ = id => document.getElementById(id);
const pageTitle = $('page-title');
const headerBtn = $('header-action-btn');
const views = { dashboard: $('view-dashboard'), pets: $('view-pets'), detail: $('view-pet-detail') };
const tabs = document.querySelectorAll('.tab');

// ── Safe DOM Builder Helpers ──
function createElement(tag, attrs, children) {
    const el = document.createElement(tag);
    if (attrs) {
        Object.entries(attrs).forEach(([key, val]) => {
            if (key === 'className') el.className = val;
            else if (key === 'textContent') el.textContent = val;
            else if (key.startsWith('on')) el.addEventListener(key.slice(2).toLowerCase(), val);
            else el.setAttribute(key, val);
        });
    }
    if (children) {
        (Array.isArray(children) ? children : [children]).forEach(child => {
            if (!child) return;
            if (typeof child === 'string') el.appendChild(document.createTextNode(child));
            else el.appendChild(child);
        });
    }
    return el;
}

function clearAndAppend(parent, children) {
    parent.textContent = '';
    (Array.isArray(children) ? children : [children]).forEach(child => {
        if (child) parent.appendChild(child);
    });
}

// ── Build Duty Card (safe DOM) ──
function buildDutyCard(duty, showPetName) {
    const pet = pets.find(p => p.id === duty.petId);
    const cat = Categories[duty.category] || Categories.other;
    const ov = isOverdue(duty.dueDate, duty.isCompleted);

    const checkBtn = createElement('button', {
        className: `duty-check ${duty.isCompleted ? 'completed' : ''}`,
        textContent: duty.isCompleted ? '✓' : '',
        onClick: () => toggleDuty(duty.id)
    });

    const iconDiv = createElement('div', { className: `duty-icon ${cat.cssClass}`, textContent: cat.icon });

    const titleDiv = createElement('div', { className: `duty-title ${duty.isCompleted ? 'completed' : ''}`, textContent: duty.title });

    const metaChildren = [];
    if (showPetName) {
        metaChildren.push(createElement('span', { textContent: pet ? pet.name : 'Unknown' }));
    } else {
        metaChildren.push(createElement('span', { textContent: formatDateTime(duty.dueDate) }));
    }
    if (ov && showPetName) {
        metaChildren.push(createElement('span', { className: 'badge-overdue', textContent: 'Overdue' }));
    }
    if (duty.isRecurring) {
        const recLabel = showPetName ? '↻' : `↻ ${Recurrences.find(r => r.value === duty.recurrenceInterval)?.label || ''}`;
        metaChildren.push(createElement('span', { className: 'badge-recurring', textContent: recLabel }));
    }
    const metaDiv = createElement('div', { className: 'duty-meta' }, metaChildren);
    const infoDiv = createElement('div', { className: 'duty-info' }, [titleDiv, metaDiv]);

    const rowChildren = [checkBtn, iconDiv, infoDiv];

    if (showPetName) {
        rowChildren.push(createElement('span', { className: 'duty-time', textContent: formatTime(duty.dueDate) }));
    } else {
        if (ov) {
            rowChildren.push(createElement('div', { className: 'overdue-indicator', textContent: '!' }));
        }
        const editBtn = createElement('button', { className: 'duty-action-btn', title: 'Edit', textContent: '✎', onClick: () => openDutyModal(duty.petId, duty.id) });
        const delBtn = createElement('button', { className: 'duty-action-btn delete', title: 'Delete', textContent: '✕', onClick: () => confirmDeleteDuty(duty.id) });
        rowChildren.push(createElement('div', { className: 'duty-actions' }, [editBtn, delBtn]));
    }

    const row = createElement('div', { className: 'duty-row' }, rowChildren);
    return createElement('div', { className: 'card' }, [row]);
}

// ── Navigation ──
function showView(name, opts) {
    opts = opts || {};
    currentView = name;

    Object.values(views).forEach(v => v.classList.remove('active'));

    tabs.forEach(t => {
        t.classList.remove('active');
        if (name === 'dashboard' && t.dataset.tab === 'dashboard') t.classList.add('active');
        if ((name === 'pets' || name === 'detail') && t.dataset.tab === 'pets') t.classList.add('active');
    });

    const existingBack = pageTitle.parentElement.querySelector('.back-btn');
    if (existingBack) existingBack.remove();

    if (name === 'dashboard') {
        views.dashboard.classList.add('active');
        pageTitle.textContent = 'Today';
        headerBtn.classList.add('hidden');
        renderDashboard();
    } else if (name === 'pets') {
        views.pets.classList.add('active');
        pageTitle.textContent = 'My Pets';
        headerBtn.classList.remove('hidden');
        headerBtn.onclick = function(e) { e.stopPropagation(); openPetModal(); };
        renderPetsList();
    } else if (name === 'detail') {
        views.detail.classList.add('active');
        currentPetId = opts.petId;
        filterCompleted = false;
        const pet = pets.find(p => p.id === currentPetId);
        pageTitle.textContent = pet ? pet.name : 'Pet';
        headerBtn.classList.add('hidden');

        const backBtn = createElement('button', {
            className: 'back-btn',
            textContent: '‹ Back',
            onClick: () => showView('pets')
        });
        pageTitle.parentElement.insertBefore(backBtn, pageTitle);

        renderPetDetail();
    }
}

// ── Tab Clicks ──
tabs.forEach(tab => {
    tab.addEventListener('click', () => {
        showView(tab.dataset.tab);
    });
});

// ── Render: Dashboard ──
function renderDashboard() {
    const el = $('dashboard-content');
    el.textContent = '';

    if (pets.length === 0) {
        const addBtn = createElement('button', { className: 'btn btn-primary', textContent: '+ Add a Pet', onClick: () => { showView('pets'); openPetModal(); } });
        const empty = createElement('div', { className: 'empty-state' }, [
            createElement('div', { className: 'empty-icon', textContent: '🐾' }),
            createElement('div', { className: 'empty-title', textContent: 'Welcome to PetTracker!' }),
            createElement('div', { className: 'empty-text', textContent: 'Add your first pet to get started.' }),
            addBtn
        ]);
        el.appendChild(empty);
        return;
    }

    const overdue = duties.filter(d => isOverdue(d.dueDate, d.isCompleted)).sort((a,b) => new Date(a.dueDate) - new Date(b.dueDate));
    const today = duties.filter(d => isToday(d.dueDate) && !d.isCompleted && !isOverdue(d.dueDate, d.isCompleted)).sort((a,b) => new Date(a.dueDate) - new Date(b.dueDate));
    const upcoming = duties.filter(d => isUpcoming(d.dueDate, d.isCompleted)).sort((a,b) => new Date(a.dueDate) - new Date(b.dueDate));

    if (overdue.length === 0 && today.length === 0 && upcoming.length === 0) {
        el.appendChild(createElement('div', { className: 'empty-state' }, [
            createElement('div', { className: 'caught-up-icon', textContent: '✅' }),
            createElement('div', { className: 'empty-title', textContent: 'All caught up!' }),
            createElement('div', { className: 'empty-text', textContent: 'No tasks due. Enjoy your time with your pets!' })
        ]));
        return;
    }

    function addSection(label, cssClass, dutyList) {
        if (dutyList.length === 0) return;
        el.appendChild(createElement('div', { className: `section-header ${cssClass}`, textContent: label }));
        dutyList.forEach(d => el.appendChild(buildDutyCard(d, true)));
    }

    addSection('Overdue', 'overdue', overdue);
    addSection('Today', 'today', today);
    addSection('Upcoming', 'upcoming', upcoming);
}

// ── Render: Pets List ──
function renderPetsList() {
    const el = $('pets-content');
    el.textContent = '';

    if (pets.length === 0) {
        el.appendChild(createElement('div', { className: 'empty-state' }, [
            createElement('div', { className: 'empty-icon', textContent: '🐾' }),
            createElement('div', { className: 'empty-title', textContent: 'No pets yet' }),
            createElement('div', { className: 'empty-text', textContent: 'Tap + to add your first furry friend!' })
        ]));
        return;
    }

    pets.forEach(pet => {
        const pending = duties.filter(d => d.petId === pet.id && !d.isCompleted).length;
        const meta = [PetTypes[pet.type]?.label || pet.type];
        if (pet.breed) meta.push(pet.breed);
        const age = petAge(pet.dateOfBirth);
        if (age) meta.push(age);

        const avatar = createElement('div', { className: `pet-avatar ${pet.type}`, textContent: PetTypes[pet.type]?.emoji || '🐾' });
        const nameEl = createElement('div', { className: 'pet-name', textContent: pet.name });
        const metaEl = createElement('div', { className: 'pet-meta', textContent: meta.join(' · ') });
        const info = createElement('div', { className: 'pet-info' }, [nameEl, metaEl]);

        const rowChildren = [avatar, info];
        if (pending > 0) {
            rowChildren.push(createElement('div', { className: 'pet-badge', textContent: String(pending) }));
        }
        rowChildren.push(createElement('span', { className: 'chevron', textContent: '›' }));

        const row = createElement('div', { className: 'pet-row' }, rowChildren);
        const card = createElement('div', { className: 'card card-clickable', onClick: () => showView('detail', { petId: pet.id }) }, [row]);
        el.appendChild(card);
    });
}

// ── Render: Pet Detail ──
function renderPetDetail() {
    const pet = pets.find(p => p.id === currentPetId);
    if (!pet) { showView('pets'); return; }
    const el = $('pet-detail-content');
    el.textContent = '';

    const allDuties = duties.filter(d => d.petId === pet.id).sort((a,b) => new Date(a.dueDate) - new Date(b.dueDate));
    const pendingCount = allDuties.filter(d => !d.isCompleted).length;
    const overdueCount = allDuties.filter(d => isOverdue(d.dueDate, d.isCompleted)).length;
    const doneCount = allDuties.filter(d => d.isCompleted).length;
    const shown = filterCompleted ? allDuties.filter(d => !d.isCompleted) : allDuties;

    const meta = [];
    if (pet.breed) meta.push(pet.breed);
    const age = petAge(pet.dateOfBirth);
    if (age) meta.push(age);
    if (pet.weight) meta.push(`${pet.weight} lbs`);

    // Header
    const editBtn = createElement('button', { className: 'detail-action-btn', textContent: 'Edit', onClick: () => openPetModal(pet.id) });
    const deleteBtn = createElement('button', { className: 'detail-action-btn danger', textContent: 'Delete', onClick: () => confirmDeletePet(pet.id) });
    const headerChildren = [
        createElement('div', { className: `detail-avatar ${pet.type}`, textContent: PetTypes[pet.type]?.emoji || '🐾' }),
        createElement('div', { className: 'detail-name', textContent: pet.name })
    ];
    if (meta.length) headerChildren.push(createElement('div', { className: 'detail-meta', textContent: meta.join(' · ') }));
    if (pet.notes) headerChildren.push(createElement('div', { className: 'detail-notes', textContent: pet.notes }));
    headerChildren.push(createElement('div', { className: 'detail-actions' }, [editBtn, deleteBtn]));
    el.appendChild(createElement('div', { className: 'detail-header' }, headerChildren));

    // Stats
    const statsBar = createElement('div', { className: 'stats-bar' }, [
        createElement('div', { className: 'stat-item' }, [
            createElement('div', { className: 'stat-count indigo', textContent: String(pendingCount) }),
            createElement('div', { className: 'stat-label', textContent: 'Pending' })
        ]),
        createElement('div', { className: 'stat-item' }, [
            createElement('div', { className: 'stat-count red', textContent: String(overdueCount) }),
            createElement('div', { className: 'stat-label', textContent: 'Overdue' })
        ]),
        createElement('div', { className: 'stat-item' }, [
            createElement('div', { className: 'stat-count green', textContent: String(doneCount) }),
            createElement('div', { className: 'stat-label', textContent: 'Done' })
        ])
    ]);
    el.appendChild(statsBar);

    // Duties header
    const filterBtn = createElement('button', { className: 'filter-btn', textContent: filterCompleted ? 'Show All' : 'Hide Done', onClick: () => { filterCompleted = !filterCompleted; renderPetDetail(); } });
    const addDutyBtn = createElement('button', { className: 'icon-btn', 'aria-label': 'Add duty', onClick: () => openDutyModal(pet.id) });
    addDutyBtn.innerHTML = '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>';
    const dutiesHeader = createElement('div', { className: 'duties-header' }, [
        createElement('h3', { textContent: 'Duties' }),
        createElement('div', { className: 'duties-header-actions' }, [filterBtn, addDutyBtn])
    ]);
    el.appendChild(dutiesHeader);

    // Duty list
    if (shown.length === 0) {
        const emptyDuties = createElement('div', { className: '', style: 'text-align:center; padding:32px 0; color:var(--text-secondary);' });
        emptyDuties.appendChild(createElement('div', { textContent: 'No duties yet', style: 'font-size:14px;' }));
        emptyDuties.appendChild(createElement('div', { textContent: 'Tap + to add feeding, walks, vet visits, and more.', style: 'font-size:12px; color:var(--text-tertiary); margin-top:4px;' }));
        el.appendChild(emptyDuties);
    } else {
        shown.forEach(duty => el.appendChild(buildDutyCard(duty, false)));
    }
}

// ── Actions ──
function toggleDuty(dutyId) {
    const idx = duties.findIndex(d => d.id === dutyId);
    if (idx === -1) return;
    duties[idx].isCompleted = !duties[idx].isCompleted;
    duties[idx].completedDate = duties[idx].isCompleted ? new Date().toISOString() : null;

    if (duties[idx].isCompleted && duties[idx].isRecurring && duties[idx].recurrenceInterval) {
        duties.push({
            id: uuid(),
            petId: duties[idx].petId,
            category: duties[idx].category,
            title: duties[idx].title,
            notes: duties[idx].notes,
            dueDate: nextRecurrence(duties[idx].dueDate, duties[idx].recurrenceInterval),
            isCompleted: false,
            completedDate: null,
            isRecurring: true,
            recurrenceInterval: duties[idx].recurrenceInterval
        });
    }

    saveDuties(duties);
    refreshCurrentView();
}

function confirmDeletePet(petId) {
    const pet = pets.find(p => p.id === petId);
    showConfirm(
        `Delete ${pet ? pet.name : 'pet'}?`,
        `This will also remove all duties for ${pet ? pet.name : 'this pet'}. This cannot be undone.`,
        () => {
            pets = pets.filter(p => p.id !== petId);
            duties = duties.filter(d => d.petId !== petId);
            savePets(pets);
            saveDuties(duties);
            showView('pets');
        }
    );
}

function confirmDeleteDuty(dutyId) {
    showConfirm('Delete this duty?', 'This cannot be undone.', () => {
        duties = duties.filter(d => d.id !== dutyId);
        saveDuties(duties);
        refreshCurrentView();
    });
}

function refreshCurrentView() {
    if (currentView === 'dashboard') renderDashboard();
    else if (currentView === 'pets') renderPetsList();
    else if (currentView === 'detail') renderPetDetail();
}

// ── Modal: Pet ──
function openPetModal(editId) {
    const pet = editId ? pets.find(p => p.id === editId) : null;
    const isEdit = !!pet;

    $('modal-title').textContent = isEdit ? 'Edit Pet' : 'Add Pet';

    let selectedType = pet ? pet.type : 'dog';

    const body = $('modal-body');
    body.textContent = '';

    // Type picker
    const typeSection = createElement('div', { className: 'form-section' });
    typeSection.appendChild(createElement('label', { className: 'form-label', textContent: 'Pet Type' }));
    const typePicker = createElement('div', { className: 'type-picker' });
    Object.entries(PetTypes).forEach(([key, val]) => {
        const opt = createElement('div', {
            className: `type-option ${selectedType === key ? 'active' : ''}`,
            'data-type': key,
            onClick: function() {
                typePicker.querySelectorAll('.type-option').forEach(o => o.classList.remove('active'));
                this.classList.add('active');
                selectedType = key;
            }
        }, [
            createElement('div', { className: 'type-circle', textContent: val.emoji }),
            createElement('div', { className: 'type-label', textContent: val.label })
        ]);
        typePicker.appendChild(opt);
    });
    typeSection.appendChild(typePicker);
    body.appendChild(typeSection);

    // Basic info
    const infoSection = createElement('div', { className: 'form-section' });
    infoSection.appendChild(createElement('label', { className: 'form-label', textContent: 'Basic Info' }));
    const nameInput = createElement('input', { className: 'form-input', id: 'pet-name', placeholder: 'Pet Name', value: pet ? pet.name : '' });
    const breedInput = createElement('input', { className: 'form-input mt-8', id: 'pet-breed', placeholder: 'Breed (optional)', value: pet ? (pet.breed || '') : '' });
    infoSection.appendChild(nameInput);
    infoSection.appendChild(breedInput);
    body.appendChild(infoSection);

    // Details
    const detailSection = createElement('div', { className: 'form-section' });
    detailSection.appendChild(createElement('label', { className: 'form-label', textContent: 'Details' }));

    const dobToggleRow = createElement('div', { className: 'toggle-row' });
    dobToggleRow.appendChild(createElement('label', { textContent: 'Date of Birth', for: 'pet-has-dob' }));
    const dobToggle = createElement('input', { type: 'checkbox', className: 'toggle', id: 'pet-has-dob' });
    if (pet && pet.dateOfBirth) dobToggle.checked = true;
    dobToggleRow.appendChild(dobToggle);
    detailSection.appendChild(dobToggleRow);

    const dobRow = createElement('div', { id: 'pet-dob-row', className: (pet && pet.dateOfBirth) ? 'mt-8' : 'hidden mt-8' });
    const dobInput = createElement('input', { type: 'date', className: 'form-input', id: 'pet-dob', value: pet && pet.dateOfBirth ? pet.dateOfBirth.split('T')[0] : '' });
    dobRow.appendChild(dobInput);
    detailSection.appendChild(dobRow);

    dobToggle.addEventListener('change', () => {
        dobRow.classList.toggle('hidden', !dobToggle.checked);
    });

    const weightRow = createElement('div', { className: 'form-row mt-8' });
    const weightInput = createElement('input', { className: 'form-input', id: 'pet-weight', placeholder: 'Weight', type: 'number', step: '0.1', value: pet && pet.weight ? String(pet.weight) : '' });
    weightRow.appendChild(weightInput);
    weightRow.appendChild(createElement('span', { className: 'form-suffix', textContent: 'lbs' }));
    detailSection.appendChild(weightRow);
    body.appendChild(detailSection);

    // Notes
    const notesSection = createElement('div', { className: 'form-section' });
    notesSection.appendChild(createElement('label', { className: 'form-label', textContent: 'Notes' }));
    const notesInput = createElement('textarea', { className: 'form-input', id: 'pet-notes', placeholder: 'Any special notes...', rows: '3' });
    notesInput.textContent = pet ? (pet.notes || '') : '';
    notesSection.appendChild(notesInput);
    body.appendChild(notesSection);

    $('modal-save').textContent = isEdit ? 'Save' : 'Add';
    $('modal-save').onclick = () => {
        const name = nameInput.value.trim();
        if (!name) return;

        const activeType = typePicker.querySelector('.type-option.active');
        const type = activeType ? activeType.dataset.type : 'dog';

        const data = {
            id: pet ? pet.id : uuid(),
            name,
            type,
            breed: breedInput.value.trim(),
            dateOfBirth: dobToggle.checked && dobInput.value ? new Date(dobInput.value).toISOString() : null,
            weight: parseFloat(weightInput.value) || null,
            notes: notesInput.value.trim()
        };

        if (isEdit) {
            const idx = pets.findIndex(p => p.id === data.id);
            if (idx >= 0) pets[idx] = data;
        } else {
            pets.push(data);
        }

        savePets(pets);
        closeModal();
        if (currentView === 'detail') {
            currentPetId = data.id;
            pageTitle.textContent = data.name;
            renderPetDetail();
        } else {
            showView('pets');
        }
    };

    showModal();
    nameInput.focus();
}

// ── Modal: Duty ──
function openDutyModal(petId, editId) {
    const duty = editId ? duties.find(d => d.id === editId) : null;
    const isEdit = !!duty;
    const pet = pets.find(p => p.id === petId);
    const availableCats = pet ? (PetTypes[pet.type]?.categories || Object.keys(Categories)) : Object.keys(Categories);

    let selectedCat = duty ? duty.category : availableCats[0];

    $('modal-title').textContent = isEdit ? 'Edit Duty' : 'New Duty';

    const body = $('modal-body');
    body.textContent = '';

    const now = new Date();
    const localISO = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    const dueVal = duty ? new Date(new Date(duty.dueDate).getTime() - new Date(duty.dueDate).getTimezoneOffset() * 60000).toISOString().slice(0, 16) : localISO;

    // Category picker
    const catSection = createElement('div', { className: 'form-section' });
    catSection.appendChild(createElement('label', { className: 'form-label', textContent: 'Category' }));
    const catPicker = createElement('div', { className: 'category-picker' });
    availableCats.forEach(key => {
        const c = Categories[key];
        const opt = createElement('button', {
            className: `cat-option ${selectedCat === key ? 'active' : ''}`,
            'data-cat': key,
            onClick: function() {
                catPicker.querySelectorAll('.cat-option').forEach(o => o.classList.remove('active'));
                this.classList.add('active');
                selectedCat = key;
                const allLabels = Object.values(Categories).map(c => c.label);
                if (!titleInput.value || allLabels.includes(titleInput.value)) {
                    titleInput.value = Categories[key]?.label || '';
                }
            }
        }, [
            createElement('span', { className: 'cat-icon', textContent: c.icon }),
            createElement('span', { className: 'cat-label', textContent: c.label })
        ]);
        catPicker.appendChild(opt);
    });
    catSection.appendChild(catPicker);
    body.appendChild(catSection);

    // Details
    const detailSection = createElement('div', { className: 'form-section' });
    detailSection.appendChild(createElement('label', { className: 'form-label', textContent: 'Details' }));
    const titleInput = createElement('input', { className: 'form-input', id: 'duty-title', placeholder: 'Task name', value: duty ? duty.title : (Categories[selectedCat]?.label || '') });
    const notesInput = createElement('textarea', { className: 'form-input mt-8', id: 'duty-notes', placeholder: 'Notes (optional)', rows: '2' });
    notesInput.textContent = duty ? (duty.notes || '') : '';
    detailSection.appendChild(titleInput);
    detailSection.appendChild(notesInput);
    body.appendChild(detailSection);

    // Schedule
    const schedSection = createElement('div', { className: 'form-section' });
    schedSection.appendChild(createElement('label', { className: 'form-label', textContent: 'Schedule' }));
    const dateInput = createElement('input', { type: 'datetime-local', className: 'form-input', id: 'duty-date', value: dueVal });
    schedSection.appendChild(dateInput);
    body.appendChild(schedSection);

    // Recurrence
    const recSection = createElement('div', { className: 'form-section' });
    recSection.appendChild(createElement('label', { className: 'form-label', textContent: 'Recurrence' }));

    const recToggleRow = createElement('div', { className: 'toggle-row' });
    recToggleRow.appendChild(createElement('label', { textContent: 'Recurring', for: 'duty-recurring' }));
    const recToggle = createElement('input', { type: 'checkbox', className: 'toggle', id: 'duty-recurring' });
    if (duty && duty.isRecurring) recToggle.checked = true;
    recToggleRow.appendChild(recToggle);
    recSection.appendChild(recToggleRow);

    const intervalRow = createElement('div', { id: 'duty-interval-row', className: (duty && duty.isRecurring) ? 'mt-8' : 'hidden mt-8' });
    const intervalSelect = createElement('select', { className: 'form-select', id: 'duty-interval' });
    Recurrences.forEach(r => {
        const option = createElement('option', { value: r.value, textContent: r.label });
        if (duty && duty.recurrenceInterval === r.value) option.selected = true;
        intervalSelect.appendChild(option);
    });
    intervalRow.appendChild(intervalSelect);
    recSection.appendChild(intervalRow);
    body.appendChild(recSection);

    recToggle.addEventListener('change', () => {
        intervalRow.classList.toggle('hidden', !recToggle.checked);
    });

    $('modal-save').textContent = isEdit ? 'Save' : 'Add';
    $('modal-save').onclick = () => {
        const title = titleInput.value.trim();
        if (!title) return;

        const activeCat = catPicker.querySelector('.cat-option.active');
        const category = activeCat ? activeCat.dataset.cat : availableCats[0];
        const isRecurring = recToggle.checked;

        const data = {
            id: duty ? duty.id : uuid(),
            petId,
            category,
            title,
            notes: notesInput.value.trim(),
            dueDate: new Date(dateInput.value).toISOString(),
            isCompleted: duty ? duty.isCompleted : false,
            completedDate: duty ? duty.completedDate : null,
            isRecurring,
            recurrenceInterval: isRecurring ? intervalSelect.value : null
        };

        if (isEdit) {
            const idx = duties.findIndex(d => d.id === data.id);
            if (idx >= 0) duties[idx] = data;
        } else {
            duties.push(data);
        }

        saveDuties(duties);
        closeModal();
        refreshCurrentView();
    };

    showModal();
    titleInput.focus();
}

// ── Modal Helpers ──
function showModal() {
    $('modal-overlay').classList.remove('hidden');
}

function closeModal() {
    $('modal-overlay').classList.add('hidden');
}

$('modal-cancel').addEventListener('click', closeModal);
$('modal-overlay').addEventListener('click', e => {
    if (e.target === $('modal-overlay')) closeModal();
});

// ── Confirm Dialog ──
function showConfirm(title, message, onConfirm) {
    $('confirm-title').textContent = title;
    $('confirm-message').textContent = message;
    $('confirm-overlay').classList.remove('hidden');

    $('confirm-yes').onclick = () => {
        $('confirm-overlay').classList.add('hidden');
        onConfirm();
    };
    $('confirm-no').onclick = () => {
        $('confirm-overlay').classList.add('hidden');
    };
}

$('confirm-overlay').addEventListener('click', e => {
    if (e.target === $('confirm-overlay')) $('confirm-overlay').classList.add('hidden');
});

// ── Init ──
showView('dashboard');
