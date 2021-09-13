function get_device_to_pm(
    ix::Int,
    load::L,
    device_formulation::Type{D},
) where {D <: Any, L <: PSY.StaticLoad}
    PM_load = Dict{String, Any}(
        "source_id" => ["bus", PSY.get_name(PSY.get_bus(load))],
        "load_bus" => PSY.get_number(PSY.get_bus(load)),
        "status" => Int64(PSY.get_available(load)),
        "qd" => PSY.get_reactive_power(load), # TODO: get load from time series
        "pd" => PSY.get_active_power(load),  # TODO: get load from time series
        "index" => ix,
    )
    return PM_load
end

function get_device_to_pm(
    ix::Int,
    shunt::L,
    device_formulation::Type{D},
) where {D <: Any, L <: PSY.FixedAdmittance}
    PM_shunt = Dict{String, Any}(
        "source_id" => ["bus", PSY.get_name(PSY.get_bus(shunt))],
        "shunt_bus" => PSY.get_number(PSY.get_bus(shunt)),
        "status" => Int64(PSY.get_available(shunt)),
        "gs" => real(PSY.get_Y(shunt)),
        "bs" => imag(PSY.get_Y(shunt)),
        "index" => ix,
    )
    return PM_shunt
end

function get_time_series_to_pm!(
    pm_data::Dict{String, Any},
    pm_category::String,
    pm_id::String,
    device::T,
    start_time::Dates.DateTime,
    time_periods::Int,
) where {T <: PSY.StaticLoad}
    psy_forecast_name = "max_active_power" # change this line for different forecasts
    pm_field_name = "pd" # change this line to apply forecast to different fields

    ts_data = PSY.get_time_series_values(
        PSY.Deterministic,
        device,
        psy_forecast_name,
        start_time = start_time,
        len = time_periods,
    )
    pm_update = Dict{String, Any}("nw" => Dict{String, Any}())
    for t in keys(pm_data["nw"])
        pm_update["nw"][t] = Dict(
            pm_category => Dict(pm_id => Dict(pm_field_name => ts_data[parse(Int, t)])),
        )
    end

    PM.update_data!(pm_data, pm_update)
end
