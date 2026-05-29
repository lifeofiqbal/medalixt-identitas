Config = {}

Config.BiayaKTP = 50000
Config.BiayaPerpanjangPerBulan = 25000
Config.MasaBerlakuKTP = 30 
Config.BiayaPraKerja = 500 
Config.CardTypes = {
    police = { label = 'POLICE', itemName = 'kta_police' },
    ambulance = { label = 'AMBULANCE', itemName = 'kta_ambulance' },
    mechanic = { label = 'MEKANIK', itemName = 'kta_mechanic' },
    pedagang = { label = 'PEDAGANG', itemName = 'kta_pedagang' },
    government = { label = 'PEMERINTAH', itemName = 'kta_government' },
    judge = { label = 'DEPARTEMENT OF JUSTICE', itemName = 'kta_judge' },
    lawyer = { label = 'LAW FIRM', itemName = 'kta_lawyer' },
}
Config.AllowedJobs = {
    ['police'] = true,
    ['ambulance'] = true,
    ['mechanic'] = true,
    ['pedagang'] = true,
    ['government'] = true,
    ['judge'] = true,
    ['lawyer'] = true,
}

Config.JobCardTypes = {
    ['police'] = 'police',
    ['ambulance'] = 'ambulance',
    ['mechanic'] = 'mechanic',
    ['pedagang'] = 'pedagang',
    ['government'] = 'government',
    ['judge'] = 'judge',
    ['lawyer'] = 'lawyer',
}

Config.Locations = {
    {
        label = "Petugas Police",
        model = 's_m_y_cop_01',
        allowedJobs = { police = true },
        cardType = 'police',
        coords = vector4(480.90, -992.14, 30.71, 93.54),
        scenario = "WORLD_HUMAN_CLIPBOARD",
    },
    {
        label = "Petugas Ambulance",
        model = 's_m_m_paramedic_01',
        allowedJobs = { ambulance = true, ems = true },
        cardType = 'ambulance',
        coords = vector4(-327.34, -586.02, 32.77, 215.43),
        scenario = "WORLD_HUMAN_CLIPBOARD",
    },
    {
        label = "Petugas Mechanic",
        model = 'mp_f_bennymech_01',
        allowedJobs = { mechanic = true },
        cardType = 'mechanic',
        coords = vector4(137.00, -3052.95, 7.04, 272.13),
        scenario = "WORLD_HUMAN_CLIPBOARD",
    },
    {
        label = "Petugas Pedagang",
        model = 'a_m_m_business_01',
        allowedJobs = { pedagang = true },
        cardType = 'pedagang',
        coords = vector4(-1908.38, -1315.20, 3.04, 317.48),
        scenario = "WORLD_HUMAN_CLIPBOARD",
    },
    {
        label = "Petugas Pemerintah",
        model = 'ig_solomon',
        allowedJobs = { government = true },
        cardType = 'government',
        coords = vector4(-431.22, 1102.40, 327.67, 348.66),
        scenario = "WORLD_HUMAN_CLIPBOARD",
    },
    {
        label = "Petugas Judge",
        model = 'csb_reporter',
        allowedJobs = { judge = true },
        cardType = 'judge',
        coords = vector4(-433.94, 1065.07, 328.57, 70.87),
        scenario = "WORLD_HUMAN_CLIPBOARD",
    },
        {
        label = "Petugas LAW FIRM",
        model = 'csb_reporter',
        allowedJobs = { lawyer = true },
        cardType = 'lawyer',
        coords = vector4(-445.03, 1068.61, 328.57, 255.12),
        scenario = "WORLD_HUMAN_CLIPBOARD",
    },
}

Config.InteractionLabel = 'Bicara Dengan Petugas'

-- Government Job Character Change Settings
Config.GovernmentCharacterChange = {
    enabled = true,
    minGrade = 3,
    minGradeName = 'Supervisor', -- Optional: display name for minimum grade
}

-- Grade levels for government job (adjust based on your server setup)
Config.GovernmentGrades = {
    { grade = 0, name = 'Pegawai' },
    { grade = 1, name = 'Kepala' },
    { grade = 2, name = 'Manajer' },
    { grade = 3, name = 'Supervisor' },
    { grade = 4, name = 'Kepala Dinas' },
    { grade = 5, name = 'Direktur' },
}