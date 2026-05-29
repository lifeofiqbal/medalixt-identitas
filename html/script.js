window.addEventListener('message', function(event) {
    const item = event.data;
    const container = document.getElementById('ktp-container');
    
    if (item.type === "showKTP") {
        const ktpData = item.data;
        const cardType = ktpData.cardType || 'ktp';
        const cardLabel = ktpData.cardLabel || (cardType === 'ktp' ? 'HELHEIM' : cardType.toUpperCase());

        container.className = '';
        container.classList.add(`card-${cardType}`);
        if (cardType !== 'ktp') container.classList.add('has-ttl');
        
        document.getElementById('card-header').innerText = cardType === 'ktp' ? 'KARTU TANDA PENDUDUK' : 'KARTU TANDA ANGGOTA';
        document.getElementById('card-subtitle').innerText = cardType === 'ktp' ? 'HELHEIM' : cardLabel;

        document.getElementById('nama-value').innerText = ktpData.nama || 'N/A';
        document.getElementById('foto-value').src = ktpData.fotourl || '';
        document.getElementById('nik-value').innerText = ktpData.nik || ktpData.citizenid || 'N/A';
        document.getElementById('ttl-value').innerText = ktpData.ttl || 'N/A';
        document.getElementById('gender-value').innerText = ktpData.gender || 'N/A';

        if (cardType === 'ktp') {
            document.getElementById('pekerjaan-value').innerText = ktpData.pekerjaan || 'TIDAK BEKERJA';
            document.getElementById('kewarganegaraan-value').innerText = ktpData.nationality || 'INDONESIA';
            const berlakuEl = document.getElementById('berlaku-value');
            if (ktpData.expires) {
                const today = new Date();
                const expiryDate = new Date(ktpData.expires);
                today.setHours(0, 0, 0, 0);
                if (expiryDate < today) {
                    berlakuEl.innerText = 'KADALUARSA';
                    berlakuEl.classList.add('expired');
                } else {
                    const day = String(expiryDate.getDate()).padStart(2, '0');
                    const month = String(expiryDate.getMonth() + 1).padStart(2, '0');
                    const year = expiryDate.getFullYear();
                    berlakuEl.innerText = `${day}-${month}-${year}`;
                    berlakuEl.classList.remove('expired');
                }
            } else {
                berlakuEl.innerText = 'SEUMUR HIDUP';
                berlakuEl.classList.remove('expired');
            }
            const creatorFullName = ktpData.pejabatNama || 'ADMIN';
            document.getElementById('pejabat-jabatan').innerText = ktpData.pejabatJabatan || 'PETUGAS';
            document.getElementById('pejabat-nama').innerText = creatorFullName;
            document.getElementById('pejabat-signature').innerText = creatorFullName.split(' ')[0].toUpperCase();
        } else {
            document.getElementById('rank-value').innerText = ktpData.rank || '---';
            const creatorName = ktpData.issuerName || ktpData.issuerJob || '---';
            document.getElementById('issuer-signature-value').innerText = creatorName.split(' ')[0].toUpperCase();
        }

        document.getElementById('ktp-container').style.display = 'block';
    }

    if (item.type === "hideKTP") {
        document.getElementById('ktp-container').style.display = 'none';
    }
});