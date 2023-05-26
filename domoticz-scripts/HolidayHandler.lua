return {
    on = {
        timer = { "at 06:04","at 07:03" }
		},
    execute = function(dz)
        --sampleSwitch1 = dz.devices('Sample-Switch1')
		--sampleSwitch2 = dz.devices('Sample-Switch2')
        if ( dz.variables('Holiday').value ~= 'Workday' ) then
			dz.log('Holiday Detected!!!! switching off the devices' )
            --sampleSwitch1.switchOff()
			--sampleSwitch1.switchOff()
        end
    end
}