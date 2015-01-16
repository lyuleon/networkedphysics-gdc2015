#include "CompressionDemo.h"

#ifdef CLIENT

#include "Cubes.h"
#include "Global.h"
#include "Snapshot.h"
#include "protocol/Stream.h"
#include "protocol/SequenceBuffer.h"
#include "protocol/PacketFactory.h"
#include "network/Simulator.h"

static const int RightPort = 1001;

enum SnapshotMode
{
    COMPRESSION_MODE_UNCOMPRESSED,
    COMPRESSION_MODE_ORIENTATION,
    COMPRESSION_MODE_AT_REST,
    COMPRESSION_MODE_VELOCITY,
    COMPRESSION_MODE_POSITION,
    COMPRESSION_NUM_MODES
};

const char * compression_mode_descriptions[]
{
    "Uncompressed",
    "Compress orientation",
    "Compress at rest",
    "Compress velocity",
    "Compress position",
};

struct CompressionModeData : public SnapshotModeData
{
    CompressionModeData()
    {
        playout_delay = 0.35f;        // one lost packet = no problem. two lost packets in a row = hitch
        send_rate = 10.0f;
        latency = 0.0f;
        packet_loss = 5.0f;
        jitter = 2 / 60.0f;
        interpolation = SNAPSHOT_INTERPOLATION_HERMITE;
    }
};

static CompressionModeData compression_mode_data[COMPRESSION_NUM_MODES];

static void InitCompressionModes()
{
//    compression_mode_data[COMPRESSION_MODE_UNCOMPRESSED]
}

enum CompressionPackets
{
    COMPRESSION_SNAPSHOT_PACKET,
    COMPRESSION_ACK_PACKET,
    COMPRESSION_NUM_PACKETS
};

struct CompressionSnapshotPacket : public protocol::Packet
{
    uint16_t sequence;
    int compression_mode;

    CompressionSnapshotPacket() : Packet( COMPRESSION_SNAPSHOT_PACKET )
    {
        sequence = 0;
        compression_mode = COMPRESSION_MODE_UNCOMPRESSED;
    }

    PROTOCOL_SERIALIZE_OBJECT( stream )
    {
        serialize_uint16( stream, sequence );

        serialize_int( stream, compression_mode, 0, COMPRESSION_NUM_MODES - 1 );

        switch ( compression_mode )
        {
            case COMPRESSION_MODE_UNCOMPRESSED:
            {
                for ( int i = 0; i < NumCubes; ++i )
                {
                    serialize_bool( stream, cubes[i].interacting );
                    serialize_vector( stream, cubes[i].position );
                    serialize_quaternion( stream, cubes[i].orientation );
                    serialize_vector( stream, cubes[i].linear_velocity );
                }
            }
            break;

            case COMPRESSION_MODE_ORIENTATION:
            {
                for ( int i = 0; i < NumCubes; ++i )
                {
                    serialize_bool( stream, cubes[i].interacting );
                    serialize_vector( stream, cubes[i].position );

                    serialize_compressed_quaternion( stream, cubes[i].orientation, 10 );

                    serialize_vector( stream, cubes[i].linear_velocity );
                }
            }
            break;

            case COMPRESSION_MODE_AT_REST:
            {
                for ( int i = 0; i < NumCubes; ++i )
                {
                    serialize_bool( stream, cubes[i].interacting );
                    serialize_vector( stream, cubes[i].position );

                    serialize_compressed_quaternion( stream, cubes[i].orientation, 10 );

                    bool at_rest;
                    if ( Stream::IsWriting )
                        at_rest = length_squared( cubes[i].linear_velocity ) == 0.0f;
                    serialize_bool( stream, at_rest );
                    if ( !at_rest )
                        serialize_vector( stream, cubes[i].linear_velocity );
                    else if ( Stream::IsReading )
                        cubes[i].linear_velocity = vectorial::vec3f::zero();
                }
            }
            break;

            case COMPRESSION_MODE_VELOCITY:
            {
                for ( int i = 0; i < NumCubes; ++i )
                {
                    serialize_bool( stream, cubes[i].interacting );
                    serialize_vector( stream, cubes[i].position );

                    serialize_compressed_quaternion( stream, cubes[i].orientation, 10 );

                    bool at_rest;
                    if ( Stream::IsWriting )
                        at_rest = length_squared( cubes[i].linear_velocity ) == 0.0f;
                    serialize_bool( stream, at_rest );
                    if ( !at_rest )
                        serialize_compressed_vector( stream, cubes[i].linear_velocity, MaxLinearSpeed, 1.0f );
                    else if ( Stream::IsReading )
                        cubes[i].linear_velocity = vectorial::vec3f::zero();
                }
            }
            break;

            case COMPRESSION_MODE_POSITION:
            {
                for ( int i = 0; i < NumCubes; ++i )
                {
                    serialize_bool( stream, cubes[i].interacting );

                    // todo: vector min/max
                    serialize_compressed_vector( stream, cubes[i].position, 40, 0.001 );

                    serialize_compressed_quaternion( stream, cubes[i].orientation, 9 );

                    bool at_rest;
                    if ( Stream::IsWriting )
                        at_rest = length_squared( cubes[i].linear_velocity ) == 0.0f;
                    serialize_bool( stream, at_rest );
                    if ( !at_rest )
                        serialize_compressed_vector( stream, cubes[i].linear_velocity, MaxLinearSpeed, 1.0f );
                    else if ( Stream::IsReading )
                        cubes[i].linear_velocity = vectorial::vec3f::zero();
                }
            }
            break;

            default:
                break;
        }
    }

    CubeState cubes[NumCubes];
};

struct CompressionAckPacket : public protocol::Packet
{
    uint16_t ack;

    CompressionAckPacket() : Packet( COMPRESSION_ACK_PACKET )
    {
        ack = 0;
    }

    PROTOCOL_SERIALIZE_OBJECT( stream )
    {
        serialize_uint16( stream, ack );
    }
};

class SnapshotPacketFactory : public protocol::PacketFactory
{
    core::Allocator * m_allocator;

public:

    SnapshotPacketFactory( core::Allocator & allocator )
        : PacketFactory( allocator, COMPRESSION_NUM_PACKETS )
    {
        m_allocator = &allocator;
    }

protected:

    protocol::Packet * CreateInternal( int type )
    {
        switch ( type )
        {
            case COMPRESSION_SNAPSHOT_PACKET:   return CORE_NEW( *m_allocator, CompressionSnapshotPacket );
            case COMPRESSION_ACK_PACKET:        return CORE_NEW( *m_allocator, CompressionAckPacket );
            default:
                return nullptr;
        }
    }
};

struct CompressionInternal
{
    CompressionInternal( core::Allocator & allocator, const SnapshotModeData & mode_data ) 
        : packet_factory( allocator ), interpolation_buffer( allocator, mode_data )
    {
        this->allocator = &allocator;
        network::SimulatorConfig networkSimulatorConfig;
        networkSimulatorConfig.packetFactory = &packet_factory;
        networkSimulatorConfig.maxPacketSize = MaxPacketSize;
        network_simulator = CORE_NEW( allocator, network::Simulator, networkSimulatorConfig );
        Reset( mode_data );
    }

    ~CompressionInternal()
    {
        CORE_ASSERT( network_simulator );
        typedef network::Simulator NetworkSimulator;
        CORE_DELETE( *allocator, NetworkSimulator, network_simulator );
        network_simulator = nullptr;
    }

    void Reset( const SnapshotModeData & mode_data )
    {
        interpolation_buffer.Reset();
        network_simulator->Reset();
        network_simulator->ClearStates();
        network_simulator->AddState( { mode_data.latency, mode_data.jitter, mode_data.packet_loss } );
        send_sequence = 0;
        recv_sequence = 0;
        send_accumulator = 1.0f;
    }

    core::Allocator * allocator;
    SnapshotPacketFactory packet_factory;
    network::Simulator * network_simulator;
    SnapshotInterpolationBuffer interpolation_buffer;
    uint16_t send_sequence;
    uint16_t recv_sequence;
    float send_accumulator;
};

CompressionDemo::CompressionDemo( core::Allocator & allocator )
{
    InitCompressionModes();
    m_allocator = &allocator;
    m_internal = nullptr;
    m_settings = CORE_NEW( *m_allocator, CubesSettings );
    m_compression = CORE_NEW( *m_allocator, CompressionInternal, *m_allocator, compression_mode_data[GetMode()] );
}

CompressionDemo::~CompressionDemo()
{
    Shutdown();
    CORE_DELETE( *m_allocator, CompressionInternal, m_compression );
    CORE_DELETE( *m_allocator, CubesSettings, m_settings );
    m_compression = nullptr;
    m_settings = nullptr;
    m_allocator = nullptr;
}

bool CompressionDemo::Initialize()
{
    if ( m_internal )
        Shutdown();

    m_internal = CORE_NEW( *m_allocator, CubesInternal );    

    CubesConfig config;
    
    config.num_simulations = 1;
    config.num_views = 2;

    m_internal->Initialize( *m_allocator, config, m_settings );

    return true;
}

void CompressionDemo::Shutdown()
{
    CORE_ASSERT( m_allocator );

    CORE_ASSERT( m_compression );
    m_compression->Reset( compression_mode_data[GetMode()] );

    if ( m_internal )
    {
        m_internal->Free( *m_allocator );
        CORE_DELETE( *m_allocator, CubesInternal, m_internal );
        m_internal = nullptr;
    }
}

void CompressionDemo::Update()
{
    CubesUpdateConfig update_config;

    auto local_input = m_internal->GetLocalInput();

    // setup left simulation to update one frame with local input

    update_config.sim[0].num_frames = 1;
    update_config.sim[0].frame_input[0] = local_input;

    // send a snapshot packet to the right simulation

    m_compression->send_accumulator += global.timeBase.deltaTime;

    if ( m_compression->send_accumulator >= 1.0f / compression_mode_data[GetMode()].send_rate )
    {
        m_compression->send_accumulator = 0.0f;   

        auto game_instance = m_internal->GetGameInstance(0);

        const int num_active_objects = game_instance->GetNumActiveObjects();

        if ( num_active_objects > 0 )
        {
            auto snapshot_packet = (CompressionSnapshotPacket*) m_compression->packet_factory.Create( COMPRESSION_SNAPSHOT_PACKET );

            snapshot_packet->sequence = m_compression->send_sequence++;

            snapshot_packet->compression_mode = GetMode();

            const hypercube::ActiveObject * active_objects = game_instance->GetActiveObjects();

            CORE_ASSERT( active_objects );

            for ( int i = 0; i < num_active_objects; ++i )
            {
                auto & object = active_objects[i];

                const int index = object.id - 1;

                CORE_ASSERT( index >= 0 );
                CORE_ASSERT( index < NumCubes );

                snapshot_packet->cubes[index].position = vectorial::vec3f( object.position.x, object.position.y, object.position.z );

                snapshot_packet->cubes[index].orientation = vectorial::quat4f( object.orientation.x, 
                                                                               object.orientation.y, 
                                                                               object.orientation.z,
                                                                               object.orientation.w );

                snapshot_packet->cubes[index].linear_velocity = vectorial::vec3f( object.linearVelocity.x, 
                                                                                  object.linearVelocity.y,
                                                                                  object.linearVelocity.z );

#ifdef SERIALIZE_ANGULAR_VELOCITY
                snapshot_packet->cubes[index].angular_velocity = vectorial::vec3f( object.angularVelocity.x, 
                                                                                   object.angularVelocity.y,
                                                                                   object.angularVelocity.z );
#endif // #ifdef SERIALIZE_ANGULAR_VELOCITY

                snapshot_packet->cubes[index].interacting = object.authority == 0;
            }

            m_compression->network_simulator->SendPacket( network::Address( "::1", RightPort ), snapshot_packet );
        }
    }

    // update the network simulator

    m_compression->network_simulator->Update( global.timeBase );

    // receive packets from the simulator (with latency, packet loss and jitter applied...)

    while ( true )
    {
        auto packet = m_compression->network_simulator->ReceivePacket();
        if ( !packet )
            break;

        const auto port = packet->GetAddress().GetPort();
        const auto type = packet->GetType();

        if ( type == COMPRESSION_SNAPSHOT_PACKET && port == RightPort )
        {
            auto snapshot_packet = (CompressionSnapshotPacket*) packet;
            m_compression->interpolation_buffer.AddSnapshot( global.timeBase.time, snapshot_packet->sequence, snapshot_packet->cubes );
        }

        m_compression->packet_factory.Destroy( packet );
    }

    // if we are an an interpolation mode, we need to grab the view updates for the right side from the interpolation buffer

    int num_object_updates = 0;

    view::ObjectUpdate object_updates[NumCubes];

    m_compression->interpolation_buffer.GetViewUpdate( compression_mode_data[GetMode()], global.timeBase.time, object_updates, num_object_updates );

    if ( num_object_updates > 0 )
        m_internal->view[1].objects.UpdateObjects( object_updates, num_object_updates );
    else
    {
        if ( m_compression->interpolation_buffer.interpolating )
            printf( "no snapshot to interpolate towards!\n" );
    }

    // run the simulation

    m_internal->Update( update_config );
}

bool CompressionDemo::Clear()
{
    return m_internal->Clear();
}

void CompressionDemo::Render()
{
    CubesRenderConfig render_config;

    render_config.render_mode = CUBES_RENDER_SPLITSCREEN;

    m_internal->Render( render_config );
}

bool CompressionDemo::KeyEvent( int key, int scancode, int action, int mods )
{
    return m_internal->KeyEvent( key, scancode, action, mods );
}

bool CompressionDemo::CharEvent( unsigned int code )
{
    // ...

    return false;
}

int CompressionDemo::GetNumModes() const
{
    return COMPRESSION_NUM_MODES;
}

const char * CompressionDemo::GetModeDescription( int mode ) const
{
    return compression_mode_descriptions[mode];
}

#endif // #ifdef CLIENT