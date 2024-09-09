
$(() => {
    var clicks = []

    window.addEventListener('message', function(ev) {
        let event = ev.data;

        if (event.type == 'showUI') {
            $(".mainFrame").fadeIn(150);
        } else if(event.type == 'setOwnedVehicles') {
            insertOwnedVehicles(event.vehicles)
        } else if(event.type == 'setBuyableVehicles') {
            insertBuyableVehicles(event.vehicles)
        } else if(event.type == 'setUI') {
            $(".title").html(event.name)
        }
    })

    const insertOwnedVehicles = (vehicles) => {
        clicks.forEach((click) => { $("#" + click).off('click')})

        for (const [key, value] of Object.entries(vehicles)) {
            let imageURL = `https://raw.githubusercontent.com/angelkaz/fivem-vehicles/master/${value.model}.png`;
            if (value.imageURL != "" && value.imageURL != null) imageURL = value.imageURL;
            let id = "vehItem" + value.model;

            $(".itemHolder").append(`
                <div class="vehItem">
                    <div class="vehicle_info"> <h1>${value.showName}</h1> <h1>${value.amount}</h1> </div>
                    <img src="${imageURL}" alt="Must Be A Custom Vehicle, talk with the developer">
                    <button id="${id}"> <p> Take Out </p> </button>
                </div>
            `)

            $("#" + id).on('click', () => {
                $.post('https://buller-jobgarage/takeOutVehicle', JSON.stringify({ model: value.model }));
                closeUI();
            })

            clicks.push(id);
        }
    }
    
    const insertBuyableVehicles = (vehicles) => {
        for (const [key, value] of Object.entries(vehicles)) {
            let imageURL = `https://raw.githubusercontent.com/angelkaz/fivem-vehicles/master/${value.model}.png`;
            if (value.imageURL != "" && value.imageURL != null) imageURL = value.imageURL;
            let id = "vehBuyItem" + value.model;

            $(".itemHolder").append(`
                <div class="vehItem">
                    <div class="vehicle_info"> <h1>${value.showName}</h1> <h1>${value.price.toLocaleString()}$</h1> </div>
                    <img src="${imageURL}" alt="Vehicle">
                    <div class="btnHolder">
                        <button id="${id}"> <p> Buy </p> </button>
                        <input type="number" name="" id="" placeholder="Number of Cars..." min="1" max="99">
                    </div>
                </div>
            `)

            $("#" + id).on('click', () => {
                let amount = $("#" + id).siblings('input').val();
                $.post('https://buller-jobgarage/buyVehicle', JSON.stringify({ model: value.model, amount: amount }));
                closeUI()
            })

            clicks.push(id);
        }
    }

    document.onkeyup = function(data) { if (data.key == "Escape") { closeUI() } }
    $("#closeUI").on('click', () => { closeUI() })

    const closeUI = () => {
        clicks = [];
        $(".mainFrame").fadeOut(150, () => $(".itemHolder").empty());
        $.post('https://buller-jobgarage/close', JSON.stringify({}));
    }
})

