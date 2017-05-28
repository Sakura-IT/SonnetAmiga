# Copyright (c) 2015-2017 Dennis van der Boon
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
##
##      $VER: sonnet_lib.i 1.0 (15.05.15)
##
##      Library offsets for sonnet.library V1
##

####  68K Library offsets

.set _LVORunPPC              ,       -30
.set _LVOWaitForPPC          ,       -36
.set _LVOGetCPU              ,       -42
.set _LVOPowerDebugMode      ,       -48
.set _LVOAllocVec32          ,       -54
.set _LVOFreeVec32           ,       -60
.set _LVOSPrintF68K          ,       -66
.set _LVOAllocXMsg           ,       -72
.set _LVOFreeXMsg            ,       -78
.set _LVOPutXMsg             ,       -84
.set _LVOGetPPCState         ,       -90
.set _LVOSetCache68K         ,       -96
.set _LVOCreatePPCTask       ,       -102
.set _LVOCausePPCInterrupt   ,       -108

####  PPC Library offsets

.set _LVORun68K              ,       -300
.set _LVOWaitFor68K          ,       -306
.set _LVOSPrintF             ,       -312
.set _LVORun68KLowLevel      ,       -318    #PRIVATE!
.set _LVOAllocVecPPC         ,       -324
.set _LVOFreeVecPPC          ,       -330
.set _LVOCreateTaskPPC       ,       -336
.set _LVODeleteTaskPPC       ,       -342
.set _LVOFindTaskPPC         ,       -348
.set _LVOInitSemaphorePPC    ,       -354
.set _LVOFreeSemaphorePPC    ,       -360
.set _LVOAddSemaphorePPC     ,       -366
.set _LVORemSemaphorePPC     ,       -372
.set _LVOObtainSemaphorePPC  ,       -378
.set _LVOAttemptSemaphorePPC ,       -384
.set _LVOReleaseSemaphorePPC ,       -390
.set _LVOFindSemaphorePPC    ,       -396
.set _LVOInsertPPC           ,       -402
.set _LVOAddHeadPPC          ,       -408
.set _LVOAddTailPPC          ,       -414
.set _LVORemovePPC           ,       -420
.set _LVORemHeadPPC          ,       -426
.set _LVORemTailPPC          ,       -432
.set _LVOEnqueuePPC          ,       -438
.set _LVOFindNamePPC         ,       -444
.set _LVOFindTagItemPPC      ,       -450
.set _LVOGetTagDataPPC       ,       -456
.set _LVONextTagItemPPC      ,       -462
.set _LVOAllocSignalPPC      ,       -468
.set _LVOFreeSignalPPC       ,       -474
.set _LVOSetSignalPPC        ,       -480
.set _LVOSignalPPC           ,       -486
.set _LVOWaitPPC             ,       -492
.set _LVOSetTaskPriPPC       ,       -498
.set _LVOSignal68K           ,       -504
.set _LVOSetCache            ,       -510
.set _LVOSetExcHandler       ,       -516
.set _LVORemExcHandler       ,       -522
.set _LVOSuper               ,       -528
.set _LVOUser                ,       -534
.set _LVOSetHardware         ,       -540
.set _LVOModifyFPExc         ,       -546
.set _LVOWaitTime            ,       -552
.set _LVOChangeStack         ,       -558    #PRIVATE!
.set _LVOLockTaskList        ,       -564
.set _LVOUnLockTaskList      ,       -570
.set _LVOSetExcMMU           ,       -576
.set _LVOClearExcMMU         ,       -582
.set _LVOChangeMMU           ,       -588
.set _LVOGetInfo             ,       -594
.set _LVOCreateMsgPortPPC    ,       -600
.set _LVODeleteMsgPortPPC    ,       -606
.set _LVOAddPortPPC          ,       -612
.set _LVORemPortPPC          ,       -618
.set _LVOFindPortPPC         ,       -624
.set _LVOWaitPortPPC         ,       -630
.set _LVOPutMsgPPC           ,       -636
.set _LVOGetMsgPPC           ,       -642
.set _LVOReplyMsgPPC         ,       -648
.set _LVOFreeAllMem          ,       -654
.set _LVOCopyMemPPC          ,       -660
.set _LVOAllocXMsgPPC        ,       -666
.set _LVOFreeXMsgPPC         ,       -672
.set _LVOPutXMsgPPC          ,       -678
.set _LVOGetSysTimePPC       ,       -684
.set _LVOAddTimePPC          ,       -690
.set _LVOSubTimePPC          ,       -696
.set _LVOCmpTimePPC          ,       -702
.set _LVOSetReplyPortPPC     ,       -708
.set _LVOSnoopTask           ,       -714
.set _LVOEndSnoopTask        ,       -720
.set _LVOGetHALInfo          ,       -726
.set _LVOSetScheduling       ,       -732
.set _LVOFindTaskByID        ,       -738
.set _LVOSetNiceValue        ,       -744
.set _LVOTrySemaphorePPC     ,       -750
.set _LVOAllocPrivateMem     ,       -756    #PRIVATE!
.set _LVOFreePrivateMem      ,       -762    #PRIVATE!
.set _LVOResetCPU            ,       -768    #PRIVATE!
.set _LVONewListPPC          ,       -774
.set _LVOSetExceptPPC        ,       -780
.set _LVOObtainSemaphoreSharedPPC    ,       -786
.set _LVOAttemptSemaphoreSharedPPC   ,       -792
.set _LVOProcurePPC          ,       -798
.set _LVOVacatePPC           ,       -804
.set _LVOCauseInterrupt      ,       -810
.set _LVOCreatePoolPPC       ,       -816
.set _LVODeletePoolPPC       ,       -822
.set _LVOAllocPooledPPC      ,       -828
.set _LVOFreePooledPPC       ,       -834
.set _LVORawDoFmtPPC         ,       -840
.set _LVOPutPublicMsgPPC     ,       -846
.set _LVOAddUniquePortPPC    ,       -852
.set _LVOAddUniqueSemaphorePPC       ,       -858
.set _LVOIsExceptionMode     ,       -864
.set _LVOCreateMsgFramePPC   ,       -870    #PRIVATE
.set _LVOSendMsgFramePPC     ,       -876    #PRIVATE
.set _LVOFreeMsgFramePPC     ,       -882    #PRIVATE
.set _LVOStartSystem         ,       -888    #PRIVATE
