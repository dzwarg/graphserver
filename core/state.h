#ifndef _STATE_H_
#define _STATE_H_

#include <stdint.h>

//---------------DECLARATIONS FOR STATE CLASS---------------------

struct State {
   uint64_t      time;           //seconds since the epoch
   uint64_t      weight;
   double        dist_walked;    //meters
   int           num_transfers;
   EdgePayload*  prev_edge;
   char*         trip_id;
   int           stop_sequence;
   int           n_agencies;
   ServicePeriod** service_periods;
} ;

State*
stateNew(int numcalendars, long time);

void
stateDestroy( State* this);

State*
stateDup( State* this );

uint64_t
stateGetTime( State* this );

uint64_t
stateGetWeight( State* this);

double
stateGetDistWalked( State* this );

int
stateGetNumTransfers( State* this );

EdgePayload*
stateGetPrevEdge( State* this );

char*
stateGetTripId( State* this );

int
stateGetStopSequence( State* this );

int
stateGetNumAgencies( State* this );

ServicePeriod*
stateServicePeriod( State* this, int agency );

void
stateSetServicePeriod( State* this,  int agency, ServicePeriod* cal );

void
stateSetTime( State* this, uint64_t time );

void
stateSetWeight( State* this, uint64_t weight );

void
stateSetDistWalked( State* this, double dist );

void
stateSetNumTransfers( State* this, int n);

// the state does not keep ownership of the trip_id, so the state
// may not live longer than whatever object set its trip_id
void
stateDangerousSetTripId( State* this, char* trip_id );

void
stateSetPrevEdge( State* this, EdgePayload* edge );

#endif
