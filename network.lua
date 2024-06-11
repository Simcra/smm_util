---@diagnostic disable:undefined-global

local adjacent_vectors = {
    vector.new(-1, 0, 0), -- -x
    vector.new(0, -1, 0), -- -y
    vector.new(0, 0, -1), -- -z
    vector.new(1, 0, 0),  -- +x
    vector.new(0, 1, 0),  -- +y
    vector.new(0, 0, 1),  -- +z
}

function smm_util.does_node_connect(source_node, target_node)
    local source_node_name = source_node.name
    local source_node_definition = minetest.registered_nodes[source_node_name]
    local source_node_connects_to = smm_util.create_lookup_table(source_node_definition.connects_to)
    local target_node_name = target_node.name
    local target_node_definition = minetest.registered_nodes[target_node_name]

    if source_node_connects_to[target_node_name] then return true end
    for _, group in pairs(target_node_definition.groups) do
        if source_node_connects_to[group] then return true end
    end
    return false
end

function smm_util.get_connectable_nodes(position)
    local node = minetest.get_node_or_nil(position)

    local connectable_nodes = {}
    for _, adjacent_vector in ipairs(adjacent_vectors) do
        local other_position = vector.add(position, adjacent_vector)
        local other_node = minetest.get_node_or_nil(other_position)

        if smm_util.does_node_connect(node, other_node) then
            table.insert(connectable_nodes, {
                node = other_node,
                position = other_position,
                meta = minetest.get_meta(other_position),
            })
        end
    end

    return connectable_nodes
end

-- Creating a simple energy network
-- 1. place a cable down
--      if the cable is not connected to any nodes, we create a new energy network
--      if the cable is connected to any nodes, get a list of all connected nodes, positions and networks attached and then merge the networks if required
--      network should be identifiable and stored in mod storage, metadata at position should only store the network identifier
-- 2. place down a cable connecting to the existing one
--      the cable should be added to the existing network and any other adjacent networks should be merged as required
-- 3. place down a producer connecting to one of the existing cables
--      the producer should be added to the network and ready to output
-- 4. place down a consumer connecting to one of the existing cables
--      the consumer should be added to the network and start consuming power
-- 5. place down a storage connecting to one of the existing cables
--      the storage should start absorbing power if there is an oversaturation the power network

function smm_util.get_connectable_networks(type, position)
    local node = minetest.get_node_or_nil(position)

    local connectable_networks = {}
    for _, adjacent_vector in ipairs(adjacent_vectors) do
        local other_position = vector.add(position, adjacent_vector)
        local other_node = minetest.get_node_or_nil(other_position)

        if smm_util.does_node_connect(node, other_node) then
            local meta = minetest.get_meta(other_position)
            local meta_networks = meta:get("smm_networks")
            if meta_networks == nil then goto continue end
            local networks = minetest.deserialize(meta_networks)
            if networks == nil or networks[type] == nil then goto continue end

            table.insert(connectable_networks, {
                position = other_position,
                network = networks[type]
            })
        end

        ::continue::
    end

    return connectable_networks
end

function smm_util.create_network(type, position)
    local meta = minetest.get_meta(position)
    local meta_networks = meta:get("smm_networks")
    local networks = {}
    if meta_networks ~= nil then networks = minetest.deserialize(meta_networks) end
    if networks[type] ~= nil then return networks[type] end

    networks[type] = {
        is_master_node = true,
        connected_nodes = {},
    }
end
