local QBCore = exports['qb-core']:GetCoreObject()
local PlayerCooldowns = {}

local function NormalizeKtpMetadata(metadata)
    if not metadata then
        return { ktp = nil, licenses = {} }
    end

    if metadata.ktp or metadata.licenses then
        metadata.licenses = metadata.licenses or {}
        return metadata
    end

    local normalized = { ktp = nil, licenses = {} }
    if metadata.cardType == 'ktp' or metadata.type == 'ktp' or not metadata.cardType then
        normalized.ktp = metadata
    else
        normalized.licenses[metadata.cardType] = metadata
    end
    return normalized
end

local function CopyTable(source)
    if type(source) ~= 'table' then return source end
    local copy = {}
    for k,v in pairs(source) do
        if type(v) == 'table' then
            copy[k] = CopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function GetCardMetadata(player, cardType)
    local meta = NormalizeKtpMetadata(player.PlayerData.metadata.ktpdata)
    if cardType == 'ktp' then
        return meta.ktp
    end
    return meta.licenses[cardType]
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

QBCore.Functions.CreateUseableItem('ktp', function(source, item)
    TriggerClientEvent('medalixt_identitas:client:openKtpUseMenu', source, { cardType = 'ktp' })
end)

for cardType, cardData in pairs(Config.CardTypes) do
    if cardData.itemName and cardData.itemName ~= 'ktp' then
        QBCore.Functions.CreateUseableItem(cardData.itemName, function(source, item)
            TriggerClientEvent('medalixt_identitas:client:openKtpUseMenu', source, { cardType = cardType })
        end)
    end
end

RegisterNetEvent('medalixt_identitas:server:showKtpToNearby', function(cardType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local dataToShow = GetCardMetadata(Player, cardType or 'ktp')
    if not dataToShow then return end

    dataToShow = CopyTable(dataToShow)
    dataToShow.pekerjaan = Player.PlayerData.job.label
    dataToShow.rank = GetJobRank(Player.PlayerData.job)
    dataToShow.telepon = Player.PlayerData.charinfo.phone
    dataToShow.cardType = cardType or 'ktp'

    for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
        if playerId ~= src and (#(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(playerId))) < 5.0) then
            TriggerClientEvent('medalixt_identitas:client:receiveKtpOffer', playerId, dataToShow)
        end
    end
end)

RegisterNetEvent('medalixt_identitas:server:buatKtpUntukWarga', function(targetId, fotoUrl, expiresDate)
    local src = source
    local Petugas = QBCore.Functions.GetPlayer(src)
    if not Petugas or not Config.AllowedJobs[Petugas.PlayerData.job.name] then return end
    
    local Warga = QBCore.Functions.GetPlayer(targetId)
    if not Warga then
        TriggerClientEvent('QBCore:Notify', src, "ID Warga tidak ditemukan.", "error")
        return
    end
    
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetId))) > 5.0 then TriggerClientEvent('QBCore:Notify', src, "Warga terlalu jauh.", "error"); return end
    if not string.match(expiresDate, "%d%d%d%d%-%d%d%-%d%d") then TriggerClientEvent('QBCore:Notify', src, "Format tanggal salah. Gunakan YYYY-MM-DD.", "error"); return end

    if Warga.PlayerData.money.bank < Config.BiayaKTP then
        TriggerClientEvent('QBCore:Notify', src, "Warga tidak punya cukup uang di bank.", "error")
        TriggerClientEvent('QBCore:Notify', targetId, "Uang Anda di bank tidak cukup.", "error")
        return
    end

    Warga.Functions.RemoveMoney('bank', Config.BiayaKTP, 'pembuatan-ktp')
    
    local charinfo = Warga.PlayerData.charinfo
    local ktpData = {
        type = 'ktp',
        cardType = 'ktp',
        cardLabel = 'KTP',
        citizenid = Warga.PlayerData.citizenid, nik = Warga.PlayerData.citizenid,
        nama = ('%s %s'):format(charinfo.firstname, charinfo.lastname):upper(),
        ttl = ('LOS SANTOS, %s'):format(charinfo.birthdate), gender = (charinfo.gender == 0 and 'LAKI-LAKI' or 'PEREMPUAN'),
        fotourl = fotoUrl, birthdate = charinfo.birthdate,
        expires = expiresDate, nationality = charinfo.nationality or "WNI",
        pejabatJabatan = Petugas.PlayerData.job.label or 'PETUGAS',
        pejabatNama = ('%s %s'):format(Petugas.PlayerData.charinfo.firstname, Petugas.PlayerData.charinfo.lastname):upper()
    }

    local existingMetadata = NormalizeKtpMetadata(Warga.PlayerData.metadata.ktpdata)
    existingMetadata.ktp = ktpData
    Warga.Functions.SetMetaData("ktpdata", existingMetadata)
    Warga.Functions.AddItem('ktp', 1, false)
    
    TriggerClientEvent('QBCore:Notify', src, "KTP untuk " .. ktpData.nama .. " berhasil dibuat.", "success")
    TriggerClientEvent('QBCore:Notify', targetId, "KTP Anda telah dibuat oleh petugas.", "success")
end)

RegisterNetEvent('medalixt_identitas:server:buatKartuAnggota', function(targetId, cardType, fotoUrl)
    local src = source
    local Petugas = QBCore.Functions.GetPlayer(src)
    if not Petugas or not Config.AllowedJobs[Petugas.PlayerData.job.name] then return end

    if not cardType or not Config.CardTypes[cardType] then
        TriggerClientEvent('QBCore:Notify', src, "Tipe kartu tidak valid.", "error")
        return
    end

    local petugasJob = Petugas.PlayerData.job.name
    if petugasJob ~= 'government' then
        local allowedCardType = Config.JobCardTypes[petugasJob]
        if allowedCardType ~= cardType then
            TriggerClientEvent('QBCore:Notify', src, "Anda hanya bisa membuat kartu untuk job Anda sendiri.", "error")
            return
        end
    end

    local Warga = QBCore.Functions.GetPlayer(targetId)
    if not Warga then
        TriggerClientEvent('QBCore:Notify', src, "ID Warga tidak ditemukan.", "error")
        return
    end

    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetId))) > 5.0 then
        TriggerClientEvent('QBCore:Notify', src, "Warga terlalu jauh.", "error")
        return
    end

    local charinfo = Warga.PlayerData.charinfo
    local ktpData = {
        type = 'license',
        cardType = cardType,
        cardLabel = Config.CardTypes[cardType].label,
        citizenid = Warga.PlayerData.citizenid,
        nik = Warga.PlayerData.citizenid,
        nama = ('%s %s'):format(charinfo.firstname, charinfo.lastname):upper(),
        ttl = ('LOS SANTOS, %s'):format(charinfo.birthdate),
        gender = (charinfo.gender == 0 and 'LAKI-LAKI' or 'PEREMPUAN'),
        fotourl = fotoUrl,
        rank = GetJobRank(Warga.PlayerData.job),
        issuerName = ('%s %s'):format(Petugas.PlayerData.charinfo.firstname, Petugas.PlayerData.charinfo.lastname):upper(),
        issuerJob = Petugas.PlayerData.job.label,
    }

    local existingMetadata = NormalizeKtpMetadata(Warga.PlayerData.metadata.ktpdata)
    existingMetadata.licenses[cardType] = ktpData
    Warga.Functions.SetMetaData("ktpdata", existingMetadata)

    local itemName = Config.CardTypes[cardType].itemName or 'ktp'
    Warga.Functions.AddItem(itemName, 1, false)

    TriggerClientEvent('QBCore:Notify', src, "Kartu " .. ktpData.cardLabel .. " untuk " .. ktpData.nama .. " berhasil dibuat.", "success")
    TriggerClientEvent('QBCore:Notify', targetId, "Kartu Anda telah dibuat oleh petugas.", "success")
end)

RegisterNetEvent('medalixt_identitas:server:perpanjangKtpOlehPetugas', function(targetId, durasiBulan)
    local src = source
    local Petugas = QBCore.Functions.GetPlayer(src)
    if not Petugas or not Config.AllowedJobs[Petugas.PlayerData.job.name] then return end

    local Warga = QBCore.Functions.GetPlayer(targetId)
    if not Warga then TriggerClientEvent('QBCore:Notify', src, "ID Warga tidak ditemukan.", "error"); return end

    local ktpMeta = NormalizeKtpMetadata(Warga.PlayerData.metadata.ktpdata)
    local oldKtpData = ktpMeta.ktp
    if not oldKtpData then
        TriggerClientEvent('QBCore:Notify', src, "Warga ini tidak memiliki data KTP yang valid di sistem.", "error")
        return
    end

    local durasiInt = tonumber(durasiBulan)
    local biaya = Config.BiayaPerpanjangPerBulan * durasiInt
    if Warga.PlayerData.money.bank < biaya then TriggerClientEvent('QBCore:Notify', src, "Warga tidak memiliki cukup uang di bank ($"..biaya..").", "error"); return end
    Warga.Functions.RemoveMoney('bank', biaya, 'perpanjang-ktp-oleh-petugas')
    
    local y, m, d = string.match(oldKtpData.expires, "(%d+)%-(%d+)%-(%d+)")
    y, m, d = tonumber(y), tonumber(m), tonumber(d)

    m = m + durasiInt
    while m > 12 do m = m - 12; y = y + 1 end
    local newDateStr = string.format("%04d-%02d-%02d", y, m, d)
    
    local newKtpData = {
        type = 'ktp',
        cardType = 'ktp',
        cardLabel = oldKtpData.cardLabel or 'KTP',
        citizenid = oldKtpData.citizenid, nik = oldKtpData.nik, nama = oldKtpData.nama,
        ttl = oldKtpData.ttl, gender = oldKtpData.gender, fotourl = oldKtpData.fotourl,
        birthdate = oldKtpData.birthdate, expires = newDateStr, nationality = oldKtpData.nationality or "WNI",
        pejabatJabatan = oldKtpData.pejabatJabatan,
        pejabatNama = oldKtpData.pejabatNama
    }

    ktpMeta.ktp = newKtpData
    Warga.Functions.SetMetaData("ktpdata", ktpMeta)
    TriggerClientEvent('medalixt_identitas:client:updateKtpData', targetId, newKtpData)
    TriggerClientEvent('QBCore:Notify', src, "KTP untuk " .. Warga.PlayerData.charinfo.firstname .. " berhasil diperpanjang.", "success")
    TriggerClientEvent('QBCore:Notify', targetId, "KTP Anda telah diperpanjang oleh petugas.", "success")
end)

RegisterNetEvent('medalixt_identitas:server:ubahDataKependudukan', function(targetId, firstname, lastname, birthdate, gender)
    local src = source
    local Petugas = QBCore.Functions.GetPlayer(src)
    if not Petugas or Petugas.PlayerData.job.name ~= 'government' then return end
    
    local minGrade = Config.GovernmentCharacterChange.minGrade or 3
    if Petugas.PlayerData.job.grade.level < minGrade then
        TriggerClientEvent('QBCore:Notify', src, "Anda tidak memiliki grade yang cukup untuk melakukan ini.", "error")
        return
    end
    
    local Warga = QBCore.Functions.GetPlayer(targetId)
    if not Warga then
        TriggerClientEvent('QBCore:Notify', src, "ID Warga tidak ditemukan.", "error")
        return
    end
    
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetId))) > 5.0 then
        TriggerClientEvent('QBCore:Notify', src, "Warga terlalu jauh.", "error")
        return
    end
    
    -- Validate input
    if not firstname or firstname == '' or not lastname or lastname == '' then
        TriggerClientEvent('QBCore:Notify', src, "Nama depan dan belakang tidak boleh kosong.", "error")
        return
    end
    
    if not birthdate or birthdate == '' then
        TriggerClientEvent('QBCore:Notify', src, "Tanggal lahir tidak boleh kosong.", "error")
        return
    end
    
    gender = tonumber(gender) or 0
    if gender ~= 0 and gender ~= 1 then gender = 0 end
    
    -- Get citizen ID
    local citizenId = Warga.PlayerData.citizenid
    
    -- Update character data using qbx_core's SetCharInfo
    exports['qbx_core']:SetCharInfo(citizenId, 'firstname', firstname)
    exports['qbx_core']:SetCharInfo(citizenId, 'lastname', lastname)
    exports['qbx_core']:SetCharInfo(citizenId, 'birthdate', birthdate)
    exports['qbx_core']:SetCharInfo(citizenId, 'gender', gender)
    
    -- Update player data in memory
    Warga.PlayerData.charinfo.firstname = firstname
    Warga.PlayerData.charinfo.lastname = lastname
    Warga.PlayerData.charinfo.birthdate = birthdate
    Warga.PlayerData.charinfo.gender = gender
    
    -- Notify both players
    TriggerClientEvent('QBCore:Notify', src, "Data kependudukan " .. firstname .. " " .. lastname .. " berhasil diubah.", "success")
    TriggerClientEvent('QBCore:Notify', targetId, "Data kependudukan Anda telah diubah oleh petugas pemerintah.", "primary")
end)

QBCore.Commands.Add('resetktp', 'Reset data KTP pemain.', {{name='id', help='ID Server pemain'}}, true, function(source, args)
    local targetId = tonumber(args[1])
    if not targetId then return end
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then return end
    TargetPlayer.Functions.SetMetaData("ktpdata", nil)
    TriggerClientEvent('QBCore:Notify', source, "Data KTP untuk ID "..targetId.." telah direset.", "success")
    TriggerClientEvent('QBCore:Notify', targetId, "Data KTP Anda telah direset oleh admin.", "primary")
end, 'admin')