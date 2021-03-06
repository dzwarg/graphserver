#ifndef _LIST_H_
#define _LIST_H_

struct ListNode {
   Edge* data;
   ListNode* next;
} ;

//LIST FUNCTIONS

/*
 * create a new list
 */
ListNode*
liNew(Edge *data);

/*
 * append an existing list node after the given list node
 */
void
liInsertAfter( ListNode *self, ListNode *add) ;

void
liRemoveAfter( ListNode *self ) ;

void
liRemoveRef( ListNode *dummyhead, Edge* data );

Edge*
liGetData( ListNode *self );

ListNode*
liGetNext( ListNode *self );

#endif