local QBCore = exports['qb-core']:GetCoreObject()
local lib = lib or exports.ox_lib
local spawnedPeds, isKtpVisible = {}, false
local LicenseTypeLabels = {
    police = 'POLICE',
    weapon_license = 'LISENSI SENJATA',
    ambulance = 'AMBULANCE',
    mechanic = 'MEKANIK',
    pedagang = 'PEDAGANG',
    government = 'PEMERINTAH',
    judge = 'DOJ',
    lawyer = 'LAW FIRM',
}

local function HideKtpUI()
    if not isKtpVisible then return end
    SendNUIMessage({ type = 'hideKTP' })
    isKtpVisible = false
    ClearPedTasks(PlayerPedId()) 
end

RegisterNetEvent('medalixt_identitas:client:openKtpUseMenu', function(args)
    local cardType = args and args.cardType or 'ktp'
    lib.registerContext({
        id = 'medalixt_identitas_use_ktp_menu',
        title = 'Pilih Aksi',
        position = 'top-right',
        options = {
            {
                title = 'Lihat Kartu Sendiri',
                metadata = { 'Hanya menampilkan kartu di layar Anda.' },
                icon = 'fas fa-id-card',
                event = 'medalixt_identitas:client:executeShowKtp',
                args = { broadcast = false, cardType = cardType }
            },
            {
                title = 'Tunjukkan ke Sekitar',
                metadata = { 'Menawarkan kartu Anda ke pemain terdekat.' },
                icon = 'fas fa-id-card',
                event = 'medalixt_identitas:client:executeShowKtp',
                args = { broadcast = true, cardType = cardType }
            },
            {
                title = 'Tutup',
                icon = 'fas fa-times',
                onSelect = function()
                    lib.hideContext()
                end
            }
        }
    })
    lib.showContext('medalixt_identitas_use_ktp_menu')
end)

local function GetPlayerCardData(cardType)
    local pData = QBCore.Functions.GetPlayerData()
    local metadata = pData.metadata.ktpdata
    if not metadata then return nil end
    if cardType == 'ktp' then
        return metadata.ktp or metadata
    end
    return metadata.licenses and metadata.licenses[cardType]
end

local function GetJobRank(job)
    if not job or type(job) ~= 'table' then return '---' end
    if job.grade then
        if job.grade.name and job.grade.name ~= '' then
            return tostring(job.grade.name):upper()
        end
        if job.grade.label and job.grade.label ~= '' then
            return tostring(job.grade.label):upper()
        end
        if job.grade.level then
            return tostring(job.grade.level)
        end
    end
    return tostring(job.grade or '---')
end

local function SetLocalCardMetadata(cardType, cardData)
    local pData = QBCore.Functions.GetPlayerData()
    pData.metadata = pData.metadata or {}
    local metadata = pData.metadata.ktpdata

    if not metadata or (not metadata.ktp and not metadata.licenses) then
        metadata = { ktp = cardType == 'ktp' and cardData or metadata, licenses = {} }
    end

    metadata.licenses = metadata.licenses or {}
    if cardType == 'ktp' then
        metadata.ktp = cardData
    else
        metadata.licenses[cardType] = cardData
    end

    pData.metadata.ktpdata = metadata
end

RegisterNetEvent('medalixt_identitas:client:executeShowKtp', function(data)
    if isKtpVisible then return end
    
    local cardType = data and data.cardType or 'ktp'
    local ktpData = GetPlayerCardData(cardType)
    if not ktpData then
        QBCore.Functions.Notify("Data KTP atau kartu Anda tidak ditemukan. Silakan buat kartu melalui petugas.", "error")
        return
    end

    local playerJob = QBCore.Functions.GetPlayerData().job
    local dataToShow = {
        type = ktpData.type,
        cardType = ktpData.cardType,
        cardLabel = ktpData.cardLabel,
        citizenid = ktpData.citizenid,
        nik = ktpData.nik,
        nama = ktpData.nama,
        ttl = ktpData.ttl,
        gender = ktpData.gender,
        fotourl = ktpData.fotourl,
        birthdate = ktpData.birthdate,
        expires = ktpData.expires,
        nationality = ktpData.nationality,
        pekerjaan = playerJob and playerJob.label or 'TIDAK BEKERJA',
        telepon = ktpData.telepon,
        rank = GetJobRank(playerJob),
        issuerName = ktpData.issuerName,
        issuerJob = ktpData.issuerJob,
        pejabatJabatan = ktpData.pejabatJabatan,
        pejabatNama = ktpData.pejabatNama,
    }

    local animDict = "paper_1_rcm_alt1-9"
    RequestAnimDict(animDict); while not HasAnimDictLoaded(animDict) do Wait(10) end
    TaskPlayAnim(PlayerPedId(), animDict, "player_one_dual-9", 8.0, 8.0, -1, 49, 0, false, false, false)

    SendNUIMessage({ type = 'showKTP', data = dataToShow })
    isKtpVisible = true
    
    if data and data.broadcast then
        TriggerServerEvent('medalixt_identitas:server:showKtpToNearby', cardType)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if isKtpVisible then
            DisableControlAction(0, 177, true) -- BACKSPACE
            if IsDisabledControlJustPressed(0, 177) then HideKtpUI() end
        else
            Wait(500)
        end
    end
end)

RegisterNetEvent('medalixt_identitas:client:receiveKtpOffer', function(ktpData)
    QBCore.Functions.Notify(ktpData.nama .. " menunjukkan kartu. Tekan [G] untuk melihat.", 'primary', 7500)
    local timeout = 7500
    CreateThread(function()
        while timeout > 0 do
            Wait(1); timeout = timeout - 1
            if IsControlJustPressed(0, 47) then
                if isKtpVisible then return end 
                SendNUIMessage({ type = 'showKTP', data = ktpData })
                isKtpVisible = true
                return 
            end
        end
    end)
end)

local function SpawnNPCs()
    for _, ped in ipairs(spawnedPeds) do DeleteEntity(ped) end; spawnedPeds = {}
    for _, location in ipairs(Config.Locations) do
        RequestModel(location.model); while not HasModelLoaded(location.model) do Wait(10) end
        local ped = CreatePed(4, location.model, location.coords.x, location.coords.y, location.coords.z - 1.0, location.coords.w, false, true)
        FreezeEntityPosition(ped, true); SetEntityInvincible(ped, true); SetBlockingOfNonTemporaryEvents(ped, true)
        TaskStartScenarioInPlace(ped, location.scenario, 0, true)
        table.insert(spawnedPeds, ped)
        
        exports['ox_target']:addLocalEntity(ped, {
            {
                name = "medalixt_identitas_open_menu",
                label = Config.InteractionLabel,
                icon = "fas fa-id-card",
                distance = 2.0,
                canInteract = function()
                    local pData = QBCore.Functions.GetPlayerData()
                    if not pData.job then return false end
                    if location.allowedJobs then
                        return location.allowedJobs[pData.job.name] == true
                    end
                    return Config.AllowedJobs[pData.job.name] == true
                end,
                onSelect = function()
                    CreateThread(function()
                        TriggerEvent('medalixt_identitas:client:openMainMenu')
                    end)
                end,
            }
        })
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', SpawnNPCs)
AddEventHandler('onResourceStart', function(res) if GetCurrentResourceName() == res and QBCore.Functions.GetPlayerData().citizenid then SpawnNPCs() end end)
AddEventHandler('onResourceStop', function(res) if GetCurrentResourceName() == res then for _, ped in ipairs(spawnedPeds) do DeleteEntity(ped) end end end)
RegisterNetEvent('medalixt_identitas:client:openMainMenu', function()
    local pData = QBCore.Functions.GetPlayerData()
    local jobName = pData.job.name
    local options = {}

    if jobName == 'government' then
        local playerGrade = pData.job.grade.level
        local minGrade = Config.GovernmentCharacterChange.minGrade or 3
        
        table.insert(options, {
            title = 'Buatkan KTP untuk Warga',
            metadata = { 'Membuat KTP baru untuk warga.' },
            icon = 'fas fa-id-card',
            event = 'medalixt_identitas:client:startBuatKtpUntukWarga'
        })
        table.insert(options, {
            title = 'Buat Kartu Tanda Anggota Pemerintah',
            metadata = { 'Buatkan kartu anggota khusus PEMERINTAH.' },
            icon = 'fas fa-id-badge',
            event = 'medalixt_identitas:client:startBuatKartuAnggota',
            args = { cardType = 'government' }
        })
        table.insert(options, {
            title = 'Perpanjang KTP Warga',
            metadata = { 'Memperpanjang masa berlaku KTP warga.' },
            icon = 'fas fa-file-invoice',
            event = 'medalixt_identitas:client:startPerpanjangKtp'
        })
        
        if Config.GovernmentCharacterChange.enabled and playerGrade >= minGrade then
            table.insert(options, {
                title = 'Ubah Data Kependudukan Warga',
                metadata = { 'Mengubah data pribadi warga (nama, tanggal lahir, gender).' },
                icon = 'fas fa-user-edit',
                event = 'medalixt_identitas:client:startUbahDataKependudukan'
            })
        end
    else
        local cardType = Config.JobCardTypes[jobName]
        if cardType then
            local cardLabel = Config.CardTypes[cardType].label
            table.insert(options, {
                title = 'Buat Kartu Tanda Anggota ' .. cardLabel,
                metadata = { 'Buatkan kartu anggota khusus ' .. cardLabel .. '.' },
                icon = 'fas fa-id-badge',
                event = 'medalixt_identitas:client:startBuatKartuAnggota',
                args = { cardType = cardType }
            })
        end

        if jobName == 'police' then
            table.insert(options, {
                title = 'Buat Lisensi Senjata',
                metadata = { 'Buatkan lisensi senjata untuk warga.' },
                icon = 'fas fa-id-card',
                event = 'medalixt_identitas:client:startBuatLisensiSenjata'
            })
            table.insert(options, {
                title = 'Perpanjang Lisensi Senjata',
                metadata = { 'Perpanjangan hanya dapat dilakukan seminggu sekali.' },
                icon = 'fas fa-file-invoice',
                event = 'medalixt_identitas:client:startPerpanjangLisensiSenjata'
            })
        end
    end

    table.insert(options, {
        title = 'Tutup',
        icon = 'fas fa-times',
        onSelect = function()
            lib.hideContext()
        end
    })

    lib.registerContext({
        id = 'medalixt_identitas_main_menu',
        title = 'Layanan Kependudukan',
        position = 'top-right',
        options = options
    })
    lib.showContext('medalixt_identitas_main_menu')
end)

RegisterNetEvent('medalixt_identitas:client:startBuatLisensiSenjata', function()
    local dialog = lib.inputDialog('Buat Lisensi Senjata', {
        { type = 'number', label = 'ID Server Warga', required = true },
        { type = 'input', label = 'URL Foto Warga (kosongkan untuk pakai foto KTP)', required = false },
        { type = 'input', label = 'Berlaku Hingga (Contoh: 2026-12-31)', required = true },
    })
    if not dialog then return end

    local targetid = tonumber(dialog[1])
    local fotourl = dialog[2]
    local expires = dialog[3]
    if targetid and fotourl and expires then
        TriggerServerEvent('medalixt_identitas:server:buatLisensiSenjata', targetid, fotourl, expires)
    end
end)

RegisterNetEvent('medalixt_identitas:client:startPerpanjangLisensiSenjata', function()
    local dialog = lib.inputDialog('Perpanjang Lisensi Senjata', {
        { type = 'number', label = 'ID Server Warga', required = true },
    })
    if not dialog then return end

    local targetid = tonumber(dialog[1])
    if targetid then
        TriggerServerEvent('medalixt_identitas:server:perpanjangLisensiSenjata', targetid)
    end
end)

RegisterNetEvent('medalixt_identitas:client:startBuatKartuAnggota', function(cardData)
    local cardType = type(cardData) == 'table' and cardData.cardType or cardData
    if not cardType then return end

    local label = LicenseTypeLabels[cardType] or tostring(cardType):upper()
    local dialog = lib.inputDialog('Buat Kartu Anggota ' .. label, {
        { type = 'number', label = 'ID Server Warga', required = true },
        { type = 'input', label = 'URL Foto Warga', required = true },
    })
    if not dialog then return end

    local targetid = tonumber(dialog[1])
    local fotourl = dialog[2]
    if targetid and fotourl then
        TriggerServerEvent('medalixt_identitas:server:buatKartuAnggota', targetid, cardType, fotourl)
    end
end)

RegisterNetEvent('medalixt_identitas:client:startBuatKtpUntukWarga', function()
    local dialog = lib.inputDialog('Buat KTP untuk Warga', {
        { type = 'number', label = 'ID Server Warga', required = true },
        { type = 'input', label = 'URL Foto Warga', required = true },
        { type = 'input', label = 'Expired (Contoh: 2025-12-31)', required = true },
    })
    if not dialog then return end
    local targetid = tonumber(dialog[1])
    local fotourl = dialog[2]
    local expires = dialog[3]
    if targetid and fotourl and expires then
        TriggerServerEvent('medalixt_identitas:server:buatKtpUntukWarga', targetid, fotourl, expires)
    end
end)

RegisterNetEvent('medalixt_identitas:client:startPerpanjangKtp', function()
    local biayaPerBulan = tonumber(Config.BiayaPerpanjangPerBulan) or 25000
    local dialog = lib.inputDialog('Perpanjang KTP Warga', {
        { type = 'number', label = 'ID Server Warga', required = true },
        { type = 'select', label = 'Pilih Durasi Perpanjangan', required = true, options = {
            { value = '1', label = '1 Bulan - $' .. (biayaPerBulan * 1) },
            { value = '2', label = '2 Bulan - $' .. (biayaPerBulan * 2) },
            { value = '3', label = '3 Bulan - $' .. (biayaPerBulan * 3) },
        } },
    })
    if not dialog then return end
    local targetid = tonumber(dialog[1])
    local durasi = dialog[2]
    if targetid and durasi then
        TriggerServerEvent('medalixt_identitas:server:perpanjangKtpOlehPetugas', targetid, durasi)
    end
end)

RegisterNetEvent('medalixt_identitas:client:startUbahDataKependudukan', function()
    local dialog = lib.inputDialog('Ubah Data Kependudukan Warga', {
        { type = 'number', label = 'ID Server Warga', required = true },
        { type = 'input', label = 'Nama Depan', required = true },
        { type = 'input', label = 'Nama Belakang', required = true },
        { type = 'input', label = 'Tanggal Lahir (MM-DD-YYYY)', required = true },
        { type = 'select', label = 'Jenis Kelamin', required = true, options = {
            { value = '0', label = 'Laki-laki' },
            { value = '1', label = 'Perempuan' },
        } },
    })
    if not dialog then return end
    
    local targetid = tonumber(dialog[1])
    local firstname = dialog[2]
    local lastname = dialog[3]
    local birthdate = dialog[4]
    local gender = tonumber(dialog[5])
    
    if targetid and firstname and lastname and birthdate and gender then
        TriggerServerEvent('medalixt_identitas:server:ubahDataKependudukan', targetid, firstname, lastname, birthdate, gender)
    end
end)

RegisterNetEvent('medalixt_identitas:client:updateKtpData', function(newKtpData, cardType)
    SetLocalCardMetadata(cardType or (newKtpData and newKtpData.cardType) or 'ktp', newKtpData)
end)
